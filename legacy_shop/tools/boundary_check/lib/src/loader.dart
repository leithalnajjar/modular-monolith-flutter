// tools/boundary_check/lib/src/loader.dart
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'workspace.dart';

/// Folders that hold a package's own Dart code. Generated and platform
/// folders (build/, .dart_tool/, android/, ios/) are never read.
const _codeFolders = ['lib', 'bin', 'test', 'integration_test', 'tool'];

/// Reads every member listed in the root pubspec's `workspace:` section.
List<WorkspacePackage> loadWorkspace(Directory root) {
  final pubspec = _yaml(File(p.join(root.path, 'pubspec.yaml')));
  final members = pubspec['workspace'];
  if (members is! YamlList) {
    throw FormatException('${root.path}/pubspec.yaml has no workspace: list');
  }
  return [
    for (final dir in members.cast<String>()) _loadPackage(root, dir),
  ];
}

/// Walks up from [start] to the folder whose pubspec declares a workspace.
Directory? findWorkspaceRoot(Directory start) {
  for (var dir = start.absolute;; dir = dir.parent) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync() && _yaml(pubspec).containsKey('workspace')) {
      return dir;
    }
    if (dir.parent.path == dir.path) return null;
  }
}

WorkspacePackage _loadPackage(Directory root, String dir) {
  final pubspec = _yaml(File(p.join(root.path, dir, 'pubspec.yaml')));
  Set<String> keys(Object? section) =>
      section is YamlMap ? section.keys.cast<String>().toSet() : const {};

  return WorkspacePackage(
    name: pubspec['name'] as String,
    dir: dir,
    dependencies: keys(pubspec['dependencies']),
    devDependencies: keys(pubspec['dev_dependencies']),
    imports: [
      for (final folder in _codeFolders)
        for (final file
            in _dartFiles(Directory(p.join(root.path, dir, folder))))
          ..._readImports(root, file),
    ],
  );
}

Iterable<File> _dartFiles(Directory dir) => dir.existsSync()
    ? dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
    : const [];

/// Parses [file] (syntax only, no type resolution, so it is fast) and
/// returns its imports and exports, including conditional ones.
List<ImportRef> _readImports(Directory root, File file) {
  final result = parseString(
    content: file.readAsStringSync(),
    path: file.path,
    throwIfDiagnostics: false,
  );
  final relative = p.split(p.relative(file.path, from: root.path)).join('/');
  return [
    for (final directive
        in result.unit.directives.whereType<NamespaceDirective>())
      for (final uri in [
        directive.uri.stringValue,
        for (final config in directive.configurations) config.uri.stringValue,
      ])
        if (uri != null)
          ImportRef(
            file: relative,
            line: result.lineInfo.getLocation(directive.offset).lineNumber,
            uri: uri,
            shown: [
              for (final show
                  in directive.combinators.whereType<ShowCombinator>())
                for (final name in show.shownNames) name.name,
            ],
          ),
  ];
}

YamlMap _yaml(File file) => loadYaml(file.readAsStringSync()) as YamlMap;
