// tools/boundary_check/lib/src/owners.dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'workspace.dart';

/// One line of a CODEOWNERS file.
final class OwnerRule {
  const OwnerRule(this.pattern, this.owners, this.line);

  /// As written, such as `/modules/cart/` or `*`.
  final String pattern;
  final List<String> owners;
  final int line;

  /// The folder an anchored pattern names (`modules/cart`), or null for
  /// patterns this tool does not interpret (such as `*` or `*.md`).
  String? get folder {
    if (!pattern.startsWith('/') || pattern.contains('*')) return null;
    final path = pattern.substring(1);
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  bool covers(String dir) =>
      pattern == '*' ||
      (folder != null && (dir == folder || dir.startsWith('$folder/')));
}

/// The rules of `.github/CODEOWNERS`, the file GitHub uses to request
/// reviews from the owners of the files a pull request changes.
final class CodeOwners {
  const CodeOwners(this.rules);

  static const path = '.github/CODEOWNERS';

  final List<OwnerRule> rules;

  /// Null when the repository has no CODEOWNERS file.
  static CodeOwners? load(Directory root) {
    final file = File(p.join(root.path, path));
    return file.existsSync() ? parse(file.readAsStringSync()) : null;
  }

  static CodeOwners parse(String text) {
    final rules = <OwnerRule>[];
    for (final (index, raw) in LineSplitter.split(text).indexed) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split(RegExp(r'\s+'));
      rules.add(OwnerRule(parts.first, parts.skip(1).toList(), index + 1));
    }
    return CodeOwners(rules);
  }

  /// Like GitHub, the last matching rule wins.
  OwnerRule? ruleFor(String dir) {
    OwnerRule? found;
    for (final rule in rules) {
      if (rule.covers(dir)) found = rule;
    }
    return found;
  }
}

/// Rule `owners`: every package has an owner of its own (a catch-all `*`
/// line is not enough), and no line names a package that does not exist.
List<Violation> checkOwners(
    List<WorkspacePackage> packages, CodeOwners owners) {
  const roots = ['apps', 'modules', 'shared', 'tools'];
  return [
    for (final pkg in packages)
      if (owners.ruleFor(pkg.dir) case final rule
          when rule == null || rule.folder == null || rule.owners.isEmpty)
        Violation(
          rule: 'owners',
          location: CodeOwners.path,
          message: '${pkg.dir} has no owner of its own. Add a line such as '
              '"/${pkg.dir}/ @your-org/<team>".',
          key: 'owners ${pkg.dir}',
        ),
    for (final rule in owners.rules)
      if (rule.folder case final folder?
          when roots.contains(folder.split('/').first) &&
              !packages.any((pkg) => rule.covers(pkg.dir)))
        Violation(
          rule: 'owners',
          location: '${CodeOwners.path}:${rule.line}',
          message: '${rule.pattern} matches no package. Remove the line or '
              'fix the path (was the package moved or extracted?).',
          key: 'owners stale ${rule.pattern}',
        ),
  ];
}
