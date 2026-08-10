import 'package:flutter_date_formatter/flutter_date_formatter.dart';
import 'package:intl/intl.dart';

String formatRelativeTime(DateTime dateTime) {
  return FlutterDateFormatter.formatRelativeDateTime(
    dateTime,
    locale: 'en',
  );
}

String formatYMd(DateTime dateTime) {
  return DateFormat.yMd().format(dateTime);
}