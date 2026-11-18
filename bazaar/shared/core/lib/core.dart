/// Bazaar's shared kernel.
///
/// Everything exported here may be used by every module, so the rule is
/// strict: only small, stable building blocks with no business meaning.
library;

export 'src/clock.dart';
export 'src/failure.dart';
export 'src/money.dart';
export 'src/result.dart';
