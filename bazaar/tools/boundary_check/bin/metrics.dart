// tools/boundary_check/bin/metrics.dart
//
// The numbers to watch during a migration (Chapter 24):
//
//   dart run boundary_check:metrics
//   dart run boundary_check:metrics --imports-of app_state.dart
import 'dart:io';

import 'package:boundary_check/boundary_check.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final root = findWorkspaceRoot(Directory.current);
  if (root == null) {
    stderr.writeln('No pubspec.yaml with a workspace: section found.');
    exitCode = 2;
    return;
  }
  final packages = loadWorkspace(root);
  stdout.writeln(formatSizes(measure(root, packages)));

  final watched = args.indexOf('--imports-of');
  if (watched >= 0 && watched + 1 < args.length) {
    final name = args[watched + 1];
    stdout.writeln('imports of $name: ${importsOf(packages, name)}');
  }

  final baseline = Baseline.read(File(p.join(root.path, Baseline.fileName)));
  stdout.writeln('known violations in ${Baseline.fileName}: '
      '${baseline.keys.length}');
}
