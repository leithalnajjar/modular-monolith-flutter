// tools/boundary_check/bin/boundary_check.dart
//
//   dart run boundary_check                    check, exit 1 on violations
//   dart run boundary_check --update-baseline  accept today's violations
import 'dart:io';

import 'package:boundary_check/boundary_check.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final unknown = args.where((a) => a != '--update-baseline');
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown option ${unknown.first}. '
        'Usage: dart run boundary_check [--update-baseline]');
    exitCode = 2;
    return;
  }

  final root = findWorkspaceRoot(Directory.current);
  if (root == null) {
    stderr.writeln('No pubspec.yaml with a workspace: section found.');
    exitCode = 2;
    return;
  }

  final packages = loadWorkspace(root);
  final owners = CodeOwners.load(root);
  final violations = [
    ...checkBoundaries(packages),
    if (owners != null) ...checkOwners(packages, owners),
  ];
  final baselineFile = File(p.join(root.path, Baseline.fileName));
  final imports = packages.fold(0, (sum, pkg) => sum + pkg.imports.length);
  stdout.writeln('boundary_check: ${packages.length} packages, '
      '$imports imports');

  if (args.contains('--update-baseline')) {
    Baseline.write(baselineFile, violations);
    stdout.writeln('Baseline now lists ${_count(violations.length)}.');
    return;
  }

  final (:fresh, :known, :fixed) =
      Baseline.read(baselineFile).apply(violations);
  for (final violation in fresh) {
    stdout.writeln(violation);
  }
  if (known.isNotEmpty) {
    stdout.writeln('Known: ${_count(known.length)} in ${Baseline.fileName}.');
  }
  if (fixed.isNotEmpty) {
    stdout.writeln('Fixed: ${_count(fixed.length)} still listed in '
        '${Baseline.fileName}. Run dart run boundary_check '
        '--update-baseline to record the progress.');
  }
  if (fresh.isNotEmpty) {
    stdout.writeln('New: ${_count(fresh.length)}.');
  } else if (fixed.isEmpty) {
    stdout.writeln('No new boundary violations.');
  }
  if (fresh.isNotEmpty || fixed.isNotEmpty) exitCode = 1;
}

String _count(int n) => n == 1 ? '1 violation' : '$n violations';
