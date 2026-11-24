import 'package:shamsi_date/shamsi_date.dart';

String faDigits(Object value) => value
    .toString()
    .replaceAll('0', '۰')
    .replaceAll('1', '۱')
    .replaceAll('2', '۲')
    .replaceAll('3', '۳')
    .replaceAll('4', '۴')
    .replaceAll('5', '۵')
    .replaceAll('6', '۶')
    .replaceAll('7', '۷')
    .replaceAll('8', '۸')
    .replaceAll('9', '۹');

const jalaliMonths = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

String formatJalali(DateTime date, {bool withYear = true}) {
  final jalali = Jalali.fromDateTime(date);
  final result = '${faDigits(jalali.day)} ${jalaliMonths[jalali.month - 1]}';
  return withYear ? '$result ${faDigits(jalali.year)}' : result;
}

String formatClock(DateTime date) =>
    '${faDigits(date.hour.toString().padLeft(2, '0'))}:${faDigits(date.minute.toString().padLeft(2, '0'))}';

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '${faDigits(h.toString().padLeft(2, '0'))}:${faDigits(m.toString().padLeft(2, '0'))}:${faDigits(s.toString().padLeft(2, '0'))}';
  }
  return '${faDigits(m.toString().padLeft(2, '0'))}:${faDigits(s.toString().padLeft(2, '0'))}';
}

String weekdayForJalali(DateTime date) {
  const names = [
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
    'شنبه',
    'یکشنبه',
  ];
  return names[date.weekday - 1];
}
