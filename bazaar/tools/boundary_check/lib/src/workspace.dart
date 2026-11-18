// tools/boundary_check/lib/src/workspace.dart

/// The role a package plays, decided by where it lives in the workspace.
enum Layer {
  app('the app'),
  module('a module implementation'),
  contract('a module contract'),
  shared('shared code'),
  tool('a tool');

  const Layer(this.description);

  /// How messages describe a package of this layer.
  final String description;

  /// Reads the layer from a member's folder, such as `modules/cart_api`.
  static Layer of(String dir) {
    final parts = dir.split('/');
    return switch (parts.first) {
      'apps' => Layer.app,
      'shared' => Layer.shared,
      'tools' => Layer.tool,
      'modules' when parts.last.endsWith('_api') => Layer.contract,
      'modules' => Layer.module,
      _ => throw FormatException(
          'Unknown workspace folder "$dir". Members live in apps/, '
          'modules/, shared/ or tools/.'),
    };
  }
}

/// One `import` or `export` directive in a Dart file.
final class ImportRef {
  const ImportRef({
    required this.file,
    required this.line,
    required this.uri,
    this.shown = const [],
  });

  /// The file containing the directive, relative to the workspace root,
  /// always with forward slashes.
  final String file;
  final int line;

  /// The URI exactly as written, such as `package:cart_api/cart_api.dart`.
  final String uri;

  /// Names listed after `show`, or empty when the directive has no `show`.
  final List<String> shown;

  /// The package a `package:` URI points into, or null for `dart:` and
  /// relative URIs.
  String? get package =>
      uri.startsWith('package:') ? uri.substring(8).split('/').first : null;

  /// Whether the URI reaches into another package's private `src/` folder.
  bool get isPrivate {
    final parts = uri.split('/');
    return package != null && parts.length > 2 && parts[1] == 'src';
  }

  /// Whether the URI is relative, such as `../inbox.dart`.
  bool get isRelative => !uri.contains(':');

  String get location => '$file:$line';
}

/// A member of the workspace, as read from its pubspec and its Dart files.
final class WorkspacePackage {
  WorkspacePackage({
    required this.name,
    required this.dir,
    Set<String> dependencies = const {},
    Set<String> devDependencies = const {},
    List<ImportRef> imports = const [],
  })  : layer = Layer.of(dir),
        dependencies = Set.unmodifiable(dependencies),
        devDependencies = Set.unmodifiable(devDependencies),
        imports = List.unmodifiable(imports);

  final String name;

  /// The folder, relative to the workspace root, such as `modules/cart`.
  final String dir;
  final Layer layer;
  final Set<String> dependencies;
  final Set<String> devDependencies;
  final List<ImportRef> imports;

  /// Whether [file] (relative to the workspace root) is test code, which
  /// may also use dev_dependencies.
  bool isTestFile(String file) {
    final inside = file.substring(dir.length + 1);
    return inside.startsWith('test/') || inside.startsWith('integration_test/');
  }
}

/// A broken rule, with enough context to fix it.
final class Violation {
  const Violation({
    required this.rule,
    required this.location,
    required this.message,
    required this.key,
  });

  /// A short rule name, such as `layers`.
  final String rule;

  /// Where to look: a pubspec or `file:line`.
  final String location;

  /// What is wrong and what to do instead.
  final String message;

  /// A stable identity without line numbers, used by the baseline file so
  /// that editing a file does not make a known violation look new.
  final String key;

  @override
  String toString() => '$location\n  $message [$rule]';
}
