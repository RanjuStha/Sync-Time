class ApiUrls {
  ApiUrls._();

  // ---------------- Base URLs ----------------
  static const String devBaseUrl = 'https://synctime.vip/';

  // static const String prodBaseUrl = 'https://your-production-url/';

  static const String baseUrl = devBaseUrl; // switch environments here

  /// Same as SERVER_URL in your Kotlin code
  static const String serverUrl = '${baseUrl}api/v1/';

  // ---------------- Endpoints (no leading slash) ----------------
  static const String organizationSetup = 'organization/access';
  static const String clientSetup = 'client/access';
  static const String employeeSetup = 'employee/access';
  static const String attendanceCreate = 'attendance/create';
}