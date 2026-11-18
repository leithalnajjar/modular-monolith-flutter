// tools/boundary_check/bin/affected.dart
//
// Prints the workspace packages a change could affect, comma-separated,
// for `dart run tool/check.dart --packages <list>`. Changed files come as
// arguments or, one per line, on standard input:
//
//   git diff --name-only origin/main... | dart run boundary_check:affected
import 'dart:convert';
import 'dart:io';

import 'package:boundary_check/boundary_check.dart';

Future<void> main(List<String> args) async {
  final root = findWorkspaceRoot(Directory.current);
  if (root == null) {
    stderr.writeln('No pubspec.yaml with a workspace: section found.');
    exitCode = 2;
    return;
  }
  final files = args.isNotEmpty
      ? args
      : await stdin
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();

  final affected = affectedPackages(loadWorkspace(root), files);
  stdout.writeln(affected.map((p) => p.dir).join(','));
}
