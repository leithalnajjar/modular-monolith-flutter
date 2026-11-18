// tools/boundary_check/lib/src/baseline.dart
import 'dart:io';

import 'workspace.dart';

/// Violations a team has agreed to live with for now, one key per line.
///
/// New code must be clean, old violations are tolerated, and the list may
/// only shrink: when a listed violation is fixed, the check fails until the
/// line is removed, so progress is recorded and cannot quietly slip back.
final class Baseline {
  const Baseline(this.keys);

  static const fileName = 'boundary_baseline.txt';

  final Set<String> keys;

  static Baseline read(File file) => Baseline(file.existsSync()
      ? file
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .toSet()
      : const {});

  static void write(File file, Iterable<Violation> violations) {
    final keys = violations.map((v) => v.key).toSet().toList()..sort();
    if (keys.isEmpty) {
      if (file.existsSync()) file.deleteSync();
      return;
    }
    file.writeAsStringSync([
      '# Known boundary violations. Fix them, then run',
      '# dart run boundary_check --update-baseline. Never add lines by hand.',
      ...keys,
      '',
    ].join('\n'));
  }

  /// Splits [violations] into new ones and ones this baseline already knows,
  /// and finds listed keys that no longer occur.
  ({List<Violation> fresh, List<Violation> known, List<String> fixed}) apply(
      List<Violation> violations) {
    final current = violations.map((v) => v.key).toSet();
    return (
      fresh: [
        for (final v in violations)
          if (!keys.contains(v.key)) v
      ],
      known: [
        for (final v in violations)
          if (keys.contains(v.key)) v
      ],
      fixed: (keys.difference(current).toList()..sort()),
    );
  }
}
