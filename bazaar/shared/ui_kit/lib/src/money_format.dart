import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Formats [money] for people: `$49.00`, `€12.50`, `¥1,800`.
///
/// This is the only place a [Money] value becomes a `double`, and only to
/// hand it to the formatter. Calculations never leave integer minor units.
String formatMoney(Money money, {String locale = 'en_US'}) {
  final format = NumberFormat.simpleCurrency(
    locale: locale,
    name: money.currency,
  );
  final digits = format.decimalDigits ?? 2;
  return format.format(money.minorUnits / math.pow(10, digits));
}

/// A price, formatted, in the app's style.
class PriceText extends StatelessWidget {
  const PriceText(this.money, {super.key, this.style, this.prefix = ''});

  final Money money;
  final TextStyle? style;

  /// Words before the amount, such as `Total `.
  final String prefix;

  @override
  Widget build(BuildContext context) =>
      Text('$prefix${formatMoney(money)}', style: style);
}
