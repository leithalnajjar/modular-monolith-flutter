// tool/check.dart
//
// Runs the analyzer once for the whole workspace, then the boundary check,
// then the tests of every member package that has a test/ folder. Exits
// with a non-zero code if anything fails, so CI can use it as one gate.
//
//   dart run tool/check.dart
//   dart run tool/check.dart --packages modules/cart,apps/bazaar_app
//
// With --packages, only those members' tests run (Chapter 22). The analyzer
// and the boundary check always cover the whole workspace: they are fast,
// and a change in one package can break the rules for another.
import 'dart:io';

Future<void> main(List<String> args) async {
  final members = _workspaceMembers(File('pubspec.yaml'));
  final only = _option(args, '--packages')?.split(',').toSet();
  final failed = <String>[];

  stdout.writeln('== analyze (whole workspace)');
  if (!await _run('dart', ['analyze', '--fatal-infos'], '.')) {
    failed.add('analyze');
  }

  // Chapter 18: which package may depend on which, and which imports are
  // allowed. Catches what the analyzer cannot see.
  stdout.writeln('== boundaries');
  if (!await _run('dart', ['run', 'boundary_check'], '.')) {
    failed.add('boundaries');
  }

  // Chapter 22: the package map in docs/ is generated; stale docs fail.
  stdout.writeln('== docs');
  if (!await _run('dart',
      ['run', 'boundary_check:modules', '--check', 'docs/modules.md'], '.')) {
    failed.add('docs');
  }

  final tested = [
    for (final path in members)
      if (only == null || only.contains(path)) path,
  ];
  for (final path in tested) {
    if (!Directory('$path/test').existsSync()) continue;
    final usesFlutter =
        File('$path/pubspec.yaml').readAsStringSync().contains('sdk: flutter');
    stdout.writeln('== test $path');
    final ok = usesFlutter
        ? await _run('flutter', ['test'], path)
        : await _run('dart', ['test'], path);
    if (!ok) failed.add(path);
  }

  if (failed.isEmpty) {
    stdout.writeln('All checks passed (${tested.length} of ${members.length} '
        'packages tested).');
  } else {
    stderr.writeln('Failed: ${failed.join(', ')}');
    exitCode = 1;
  }
}

/// The value after [name], as in `--packages a,b`; null when absent.
String? _option(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

/// Reads the `workspace:` list from the root pubspec without extra packages.
List<String> _workspaceMembers(File rootPubspec) {
  final members = <String>[];
  var inWorkspace = false;
  for (final line in rootPubspec.readAsLinesSync()) {
    if (line.startsWith('workspace:')) {
      inWorkspace = true;
    } else if (inWorkspace && line.trimLeft().startsWith('- ')) {
      members.add(line.trim().substring(2).trim());
    } else if (inWorkspace && line.trim().isNotEmpty) {
      break; // the next top-level key ends the list
    }
  }
  return members;
}

Future<bool> _run(String exe, List<String> args, String dir) async {
  final process = await Process.start(exe, args,
      workingDirectory: dir,
      runInShell: true,
      mode: ProcessStartMode.inheritStdio);
  return await process.exitCode == 0;
}
