class AppDateUtils {
  AppDateUtils._();

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  static String formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$m:$s $period';
  }

  static String formatDate(DateTime t) =>
      '${_days[t.weekday - 1]}, ${t.day} ${_months[t.month - 1]} ${t.year}';

  static String greeting(DateTime t) {
    if (t.hour < 12) return 'Good morning';
    if (t.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}