// tools/boundary_check/lib/src/rules.dart
import 'package:path/path.dart' as p;

import 'workspace.dart';

/// Which layers each layer may depend on. This table is the architecture
/// from Chapter 3, written down once.
const allowedDependencies = <Layer, Set<Layer>>{
  Layer.app: {Layer.module, Layer.contract, Layer.shared},
  Layer.module: {Layer.contract, Layer.shared},
  Layer.contract: {Layer.contract, Layer.shared},
  Layer.shared: {Layer.shared},
  Layer.tool: {Layer.shared},
};

/// Checks every rule and returns what is broken, in a stable order.
List<Violation> checkBoundaries(List<WorkspacePackage> packages) {
  final byName = {for (final pkg in packages) pkg.name: pkg};
  return [
    for (final pkg in packages) ...[
      ..._layers(pkg, byName),
      for (final ref in pkg.imports) ..._imports(pkg, ref, byName),
    ],
    ..._cycles(packages, byName),
  ];
}

/// Rule `layers`: a pubspec may only list packages from allowed layers.
/// Applies to dev_dependencies too: a module's tests use fakes, not other
/// modules' implementations.
Iterable<Violation> _layers(
    WorkspacePackage pkg, Map<String, WorkspacePackage> byName) sync* {
  final deps = {...pkg.dependencies, ...pkg.devDependencies};
  for (final name in deps.toList()..sort()) {
    final target = byName[name];
    if (target == null) continue; // a package from pub.dev
    if (allowedDependencies[pkg.layer]!.contains(target.layer)) continue;
    yield Violation(
      rule: 'layers',
      location: '${pkg.dir}/pubspec.yaml',
      message: '${pkg.name} is ${pkg.layer.description} and must not depend '
          'on ${target.name}, which is ${target.layer.description}. '
          '${_advice(pkg, target, byName)}',
      key: 'layers ${pkg.name} -> ${target.name}',
    );
  }
}

String _advice(WorkspacePackage from, WorkspacePackage to,
    Map<String, WorkspacePackage> byName) {
  if (to.layer == Layer.app) return 'Nothing depends on the app.';
  if (from.layer == Layer.shared) {
    return 'Shared code sits below every module and knows none of them.';
  }
  if (from.layer == Layer.tool) return 'Tools may use shared packages only.';
  final contract = '${to.name}_api';
  if (to.layer == Layer.module && byName.containsKey(contract)) {
    return 'Depend on $contract instead.';
  }
  if (from.layer == Layer.contract) {
    return 'Contracts may use shared packages and other contracts only.';
  }
  return 'Only the app may depend on module implementations.';
}

Iterable<Violation> _imports(WorkspacePackage pkg, ImportRef ref,
    Map<String, WorkspacePackage> byName) sync* {
  // Rule `outside`: a relative import must stay inside its own package.
  if (ref.isRelative) {
    final target =
        p.posix.normalize(p.posix.join(p.posix.dirname(ref.file), ref.uri));
    if (!p.posix.isWithin(pkg.dir, target)) {
      yield Violation(
        rule: 'outside',
        location: ref.location,
        message: '"${ref.uri}" reaches outside ${pkg.name}. Use a '
            'package: import of a declared dependency instead.',
        key: 'outside ${ref.file} -> ${ref.uri}',
      );
    }
    return;
  }

  final target = byName[ref.package];
  if (target == null || target == pkg) return;

  // Rule `declared`: every workspace package you import is in your
  // pubspec. In a workspace, undeclared imports compile anyway (Chapter 6).
  final declared = pkg.dependencies.contains(target.name) ||
      (pkg.isTestFile(ref.file) && pkg.devDependencies.contains(target.name));
  if (!declared) {
    yield Violation(
      rule: 'declared',
      location: ref.location,
      message: 'imports ${target.name}, which ${pkg.name}/pubspec.yaml does '
          'not list. Declare it (if the layers allow it) or remove the import.',
      key: 'declared ${ref.file} -> ${target.name}',
    );
  }

  // Rule `private`: lib/src/ is private to its package.
  if (ref.isPrivate) {
    yield Violation(
      rule: 'private',
      location: ref.location,
      message: 'imports ${ref.uri}, a private file of ${target.name}. Use '
          'what package:${target.name}/${target.name}.dart exports.',
      key: 'private ${ref.file} -> ${ref.uri}',
    );
  }

  // Rule `testing`: fakes and contract checks (Chapter 19) are for tests.
  // Production code that imported them would ship a fake catalog.
  if (ref.uri == 'package:${target.name}/testing.dart' &&
      !pkg.isTestFile(ref.file)) {
    yield Violation(
      rule: 'testing',
      location: ref.location,
      message: 'imports ${ref.uri} outside test/. Test support is for '
          'tests only; production code uses ${target.name}.dart.',
      key: 'testing ${ref.file} -> ${ref.uri}',
    );
  }

  // Rule `show`: a contract that uses another contract names exactly what
  // it uses, so reviewers see every type that crosses (usually an ID).
  if (pkg.layer == Layer.contract &&
      target.layer == Layer.contract &&
      ref.shown.isEmpty) {
    yield Violation(
      rule: 'show',
      location: ref.location,
      message: 'contract ${pkg.name} imports all of ${target.name}. Add '
          '`show` with the names it needs, such as an ID type.',
      key: 'show ${ref.file} -> ${target.name}',
    );
  }
}

/// Rule `cycles`: no package may depend on itself through others.
Iterable<Violation> _cycles(
    List<WorkspacePackage> packages, Map<String, WorkspacePackage> byName) {
  final found = <String, List<String>>{};
  final done = <String>{};

  void visit(String name, List<String> path) {
    final start = path.indexOf(name);
    if (start >= 0) {
      final cycle = path.sublist(start);
      // Rotate so each cycle is reported once, from its smallest name.
      final first = cycle.indexOf((cycle.toList()..sort()).first);
      final rotated = [...cycle.sublist(first), ...cycle.sublist(0, first)];
      found[rotated.join(' -> ')] = rotated;
      return;
    }
    if (done.contains(name)) return;
    final deps = byName[name]!.dependencies.where(byName.containsKey);
    for (final dep in deps.toList()..sort()) {
      visit(dep, [...path, name]);
    }
    done.add(name);
  }

  for (final pkg in packages) {
    visit(pkg.name, const []);
  }
  return [
    for (final MapEntry(key: chain, value: cycle) in found.entries)
      Violation(
        rule: 'cycles',
        location: '${byName[cycle.first]!.dir}/pubspec.yaml',
        message: 'dependency cycle: $chain -> ${cycle.first}. Break it with '
            'an event or by moving the shared type into a contract.',
        key: 'cycles $chain',
      ),
  ];
}
