import 'package:shared_preferences/shared_preferences.dart';

/// All preference keys in one place (avoids typos).
class PrefKeys {
  PrefKeys._();

  static const String companyName = 'company_name';
  static const String companyAddress = 'company_address';
  static const String companyTimezone = 'company_timezone';
  static const String companyImage = 'company_image';
  static const String companyId = 'company_id';
}

/// Global preferences helper: AppPrefs.save(...), AppPrefs.get(...)
class AppPrefs {
  AppPrefs._();

  static late SharedPreferences _prefs;

  /// Call once in main() before runApp.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---------------- Generic save / get ----------------

  /// Saves String, int, double, bool or List<String>.
  /// Passing null removes the key.
  static Future<bool> save(String key, Object? value) async {
    if (value == null) return _prefs.remove(key);
    if (value is String) return _prefs.setString(key, value);
    if (value is int) return _prefs.setInt(key, value);
    if (value is double) return _prefs.setDouble(key, value);
    if (value is bool) return _prefs.setBool(key, value);
    if (value is List<String>) return _prefs.setStringList(key, value);
    throw ArgumentError('Unsupported type: ${value.runtimeType}');
  }

  /// Removes only the saved organization (used on "Reset Client").
  static Future<void> clearOrganization() async {
    await remove(PrefKeys.companyName);
    await remove(PrefKeys.companyAddress);
    await remove(PrefKeys.companyTimezone);
    await remove(PrefKeys.companyImage);
    await remove(PrefKeys.companyId);
  }

  /// True when a company was saved (id is stored as a positive int).
  static bool get hasCompany => companyId > 0;
  /// Returns the saved value, or null if missing / a different type.
  /// Example: AppPrefs.get<String>('key')
  static T? get<T>(String key) {
    final value = _prefs.get(key);
    return value is T ? value : null;
  }

  static String getString(String key, {String defaultValue = ''}) =>
      _prefs.getString(key) ?? defaultValue;

  static bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  static int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  static bool has(String key) => _prefs.containsKey(key);

  static Future<bool> remove(String key) => _prefs.remove(key);

  /// Removes everything (e.g. on "Reset Client").
  static Future<bool> clear() => _prefs.clear();

  // ---------------- Organization shortcuts ----------------
  static String get companyName => getString(PrefKeys.companyName);
  static String get companyAddress => getString(PrefKeys.companyAddress);
  static String get companyTimezone => getString(PrefKeys.companyTimezone);
  static String get companyImage => getString(PrefKeys.companyImage);
  static int get companyId => getInt(PrefKeys.companyId);

  // app_prefs.dart
  static const _kClientToken = 'client_token';

  static String? get clientToken => _prefs.getString(_kClientToken);

  static Future<void> setClientToken(String token) =>
      _prefs.setString(_kClientToken, token);

  static Future<void> clearClientToken() => _prefs.remove(_kClientToken);
  /// Saves the fields from the "organizationDetail" object of the API.
  static Future<void> saveOrganization(Map detail) async {
    await save(PrefKeys.companyName, detail['name']?.toString());
    await save(PrefKeys.companyAddress, detail['address']?.toString());
    await save(PrefKeys.companyTimezone, detail['timezone']?.toString());
    await save(PrefKeys.companyImage, detail['image']?.toString());

    // Store the id as an int (the API may send it as a number or a string).
    // If it's missing or not numeric, the key is removed.
    await save(
      PrefKeys.companyId,
      int.tryParse(detail['id']?.toString() ?? ''),
    );
  }
}