// tools/boundary_check/bin/modules.dart
//
//   dart run boundary_check:modules                         print the map
//   dart run boundary_check:modules --write docs/modules.md  update the file
//   dart run boundary_check:modules --check docs/modules.md  fail if stale
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
  final map = moduleMap(loadWorkspace(root), CodeOwners.load(root));

  switch (args) {
    case ['--write', final path]:
      File(p.join(root.path, path))
        ..createSync(recursive: true)
        ..writeAsStringSync(map);
      stdout.writeln('Wrote $path');
    case ['--check', final path]:
      final file = File(p.join(root.path, path));
      final current = file.existsSync() ? file.readAsStringSync() : '';
      if (current.replaceAll('\r\n', '\n') != map) {
        stderr.writeln('$path is out of date. Run: '
            'dart run boundary_check:modules --write $path');
        exitCode = 1;
      }
    case []:
      stdout.write(map);
    default:
      stderr.writeln('Usage: dart run boundary_check:modules '
          '[--write <file> | --check <file>]');
      exitCode = 2;
  }
}
