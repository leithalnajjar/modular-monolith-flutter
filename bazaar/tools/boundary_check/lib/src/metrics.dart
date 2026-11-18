// tools/boundary_check/lib/src/metrics.dart
import 'dart:io';

import 'package:path/path.dart' as p;

import 'workspace.dart';

/// How much code a package has in `lib/`: the numbers a migration watches.
final class PackageSize {
  const PackageSize(this.package, this.files, this.lines);

  final WorkspacePackage package;
  final int files;
  final int lines;
}

/// Counts the Dart files and lines in each package's `lib/` folder. Tests
/// and tools are left out on purpose: the question is where the app's code
/// lives.
List<PackageSize> measure(Directory root, List<WorkspacePackage> packages) => [
      for (final pkg in packages)
        if (pkg.layer != Layer.tool)
          () {
            final lib = Directory(p.join(root.path, pkg.dir, 'lib'));
            final files = lib.existsSync()
                ? lib
                    .listSync(recursive: true)
                    .whereType<File>()
                    .where((f) => f.path.endsWith('.dart'))
                    .toList()
                : <File>[];
            final lines =
                files.fold(0, (sum, f) => sum + f.readAsLinesSync().length);
            return PackageSize(pkg, files.length, lines);
          }(),
    ];

/// A plain-text table of [sizes], with each package's share of all lines.
String formatSizes(List<PackageSize> sizes) {
  final total = sizes.fold(0, (sum, s) => sum + s.lines);
  final width = sizes.fold(
      7, (w, s) => s.package.dir.length > w ? s.package.dir.length : w);
  String row(String name, String layer, Object files, Object lines,
          String share) =>
      '${name.padRight(width)}  ${layer.padRight(8)}  '
      '${'$files'.padLeft(5)}  ${'$lines'.padLeft(6)}  ${share.padLeft(5)}';
  return [
    row('package', 'layer', 'files', 'lines', 'share'),
    for (final s in sizes)
      row(s.package.dir, s.package.layer.name, s.files, s.lines,
          total == 0 ? '-' : '${(100 * s.lines / total).round()}%'),
  ].join('\n');
}

/// How many import or export directives in the workspace point at a file
/// whose name is [fileName], such as `app_state.dart`.
int importsOf(List<WorkspacePackage> packages, String fileName) => [
      for (final pkg in packages)
        for (final ref in pkg.imports)
          if (ref.uri.split('/').last == fileName) ref,
    ].length;
