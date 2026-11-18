// tools/boundary_check/lib/src/affected.dart
import 'workspace.dart';

/// The packages whose checks a change to [changedFiles] could break: each
/// package that contains a changed file, and every package that depends on
/// one of those, directly or through others (dev_dependencies included,
/// because tests break too).
///
/// [changedFiles] are paths relative to the workspace root, as printed by
/// `git diff --name-only`. A change outside every package (the root
/// pubspec, the lock file, shared analysis options, CI scripts) can affect
/// anything, so it returns every package.
List<WorkspacePackage> affectedPackages(
    List<WorkspacePackage> packages, Iterable<String> changedFiles) {
  final changed = <WorkspacePackage>{};
  for (final raw in changedFiles) {
    final file = raw.trim().replaceAll(r'\', '/');
    if (file.isEmpty) continue;
    final owner = _packageOf(packages, file);
    if (owner == null) return packages; // a workspace-wide file
    changed.add(owner);
  }

  // Walk the dependency graph backwards: who depends on what changed?
  final dependents = <String, Set<WorkspacePackage>>{};
  for (final pkg in packages) {
    for (final dep in {...pkg.dependencies, ...pkg.devDependencies}) {
      (dependents[dep] ??= {}).add(pkg);
    }
  }
  final affected = <WorkspacePackage>{};
  final queue = [...changed];
  while (queue.isNotEmpty) {
    final pkg = queue.removeLast();
    if (affected.add(pkg)) queue.addAll(dependents[pkg.name] ?? const {});
  }

  // Keep the workspace's order, so output is stable.
  return [
    for (final pkg in packages)
      if (affected.contains(pkg)) pkg
  ];
}

WorkspacePackage? _packageOf(List<WorkspacePackage> packages, String file) {
  for (final pkg in packages) {
    if (file.startsWith('${pkg.dir}/')) return pkg;
  }
  return null;
}
