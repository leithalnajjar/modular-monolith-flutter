import 'package:intl/intl.dart';

/// Formats a moment as a date for people, such as `Jun 1, 2027` in US
/// English, in the user's own time zone.
///
/// Locales other than `en_US` need their date symbols loaded once at
/// startup with `initializeDateFormatting()` from
/// `package:intl/date_symbol_data_local.dart`.
String formatDate(DateTime moment, {String locale = 'en_US'}) =>
    DateFormat.yMMMd(locale).format(moment.toLocal());
