import 'package:timezone/timezone.dart' as tz;
import 'package:flexyear/services/app_prefs.dart';

/// Current time in the organization's saved timezone.
/// Falls back to the device time if none is saved or the name is invalid.
class AppTime {
  AppTime._();

  static DateTime now() {
    final name = AppPrefs.companyTimezone;
    if (name.isNotEmpty) {
      try {
        // TZDateTime is a DateTime, so hour/minute/day/weekday are in that zone
        return tz.TZDateTime.now(tz.getLocation(name));
      } catch (_) {
        // unknown timezone name: use device time below
      }
    }
    return DateTime.now();
  }
}