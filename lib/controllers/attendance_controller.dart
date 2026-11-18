import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:camera/camera.dart' show XFile;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flexyear/utils/app_time.dart';
import 'package:flexyear/services/api.dart';
import 'package:flexyear/services/api_urls.dart';
import 'package:flexyear/services/app_prefs.dart';
import 'package:flexyear/services/client_session.dart';
import 'package:flexyear/models/client_person.dart';

enum AttendanceAction { checkIn, startLunch, endLunch, checkOut }

enum AttendanceStatus { notCheckedIn, checkedIn, onLunch, lunchDone, checkedOut }

class AttendanceController extends ChangeNotifier {
  AttendanceController({
    required this.userName,
    required this.userId,
    required this.position,
    required this.code, // the PIN / employee code, sent as `token`
    required this.id,
    this.userImageUrl,
    this.onActionDone,
  }) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = AppTime.now();
    });

    // Fetch the current status as soon as the screen opens
    getStatus();
  }

  final String userName;
  final String userId;
  final String position;
  final String code;
  final String? userImageUrl;
  final int id;

  final void Function(AttendanceAction action)? onActionDone;

  // ---------------- Texts ----------------
  final String closeText = 'Close This Page';

  String get subtitle => '#$userId  •  $position';

  String labelFor(AttendanceAction a) {
    switch (a) {
      case AttendanceAction.checkIn:
        return 'Check In';
      case AttendanceAction.startLunch:
        return 'Start Lunch';
      case AttendanceAction.endLunch:
        return 'End Lunch';
      case AttendanceAction.checkOut:
        return 'Checkout';
    }
  }

  // ---------------- State ----------------
  final ValueNotifier<DateTime> now = ValueNotifier(AppTime.now());
  Timer? _timer;
  bool _disposed = false;

  AttendanceAction? loadingAction;
  bool get isLoading => loadingAction != null;

  bool isStatusLoading = false;
  String? statusError;
  String? actionError;
  Map<String, dynamic>? statusData;
  AttendanceStatus status = AttendanceStatus.notCheckedIn;

  /// Whether a button should be enabled for the current status.
  bool canDo(AttendanceAction a) {
    if (isLoading || isStatusLoading) return false;
    switch (a) {
      case AttendanceAction.checkIn:
        return status == AttendanceStatus.notCheckedIn;
      case AttendanceAction.startLunch:
        return status == AttendanceStatus.checkedIn;
      case AttendanceAction.endLunch:
        return status == AttendanceStatus.onLunch;
      case AttendanceAction.checkOut:
        return status == AttendanceStatus.checkedIn ||
            status == AttendanceStatus.lunchDone;
    }
  }

  // ---------------- Helpers ----------------
  /// Maps the button to the `mode` the API expects.
  String _modeFor(AttendanceAction a) {
    switch (a) {
      case AttendanceAction.checkIn:
        return 'checkin';
      case AttendanceAction.startLunch:
        return 'lunchin';
      case AttendanceAction.endLunch:
        return 'lunchout';
      case AttendanceAction.checkOut:
        return 'checkout';
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// "2026-11-18 03:53:52"
  String _formatDateTime(DateTime d) =>
      '${_formatDate(d)} ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

  Future<String> _deviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        final w = await info.webBrowserInfo;
        return '${w.browserName.name} on ${w.platform ?? 'Web'}'; // e.g. "safari on MacIntel"
      }
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        return '${a.manufacturer} ${a.model}'; // e.g. "samsung SM-S948U1"
      }
      if (Platform.isIOS) {
        final i = await info.iosInfo;
        return i.name; // e.g. "Ranju's iPad"
      }
      if (Platform.isMacOS) {
        final m = await info.macOsInfo;
        return m.computerName;
      }
    } catch (_) {}
    return 'Unknown';
  }

  /// Reads the captured image and returns it as a base64 data URL.
  /// Works everywhere: a file path on mobile/macOS, a blob: URL on web.
  Future<String> _imageToBase64(String path) async {
    final bytes = await XFile(path).readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  /// Searches a nested Map/List for [key] and returns the first match.
  /// Used because I can't see where exactly the API puts these ids.
  dynamic _find(dynamic source, String key) {
    if (source is Map) {
      if (source.containsKey(key) && source[key] != null) return source[key];
      for (final v in source.values) {
        final r = _find(v, key);
        if (r != null) return r;
      }
    } else if (source is List) {
      for (final v in source) {
        final r = _find(v, key);
        if (r != null) return r;
      }
    }
    return null;
  }

  // ---------------- Actions ----------------
  /// [photoPath] is the image captured for this action.
  /// Pass an empty string to send the request without an image.
  Future<void> perform(
      AttendanceAction action, {
        required String photoPath,
      }) async {
    if (!canDo(action)) return;

    actionError = null;
    loadingAction = action;
    notifyListeners();

    try {
      final image = photoPath.isEmpty ? '' : await _imageToBase64(photoPath);
      final clientDetail = ClientSession.clientDetail;

      final body = <String, dynamic>{
        'mode': _modeFor(action),
        'time': _formatDateTime(AppTime.now()),
        'userImage': image,
        'employee_id': id, // id
        'auth_id': userId, // user_id
        'organization_id': AppPrefs.companyId,
        'client_id': clientDetail['id'],
        'client_device_id': 0,
        'department_id': 0,
        'device_type': 'Tablet',
        'type': 'Tablet',
        'device_name': await _deviceName(),
        if (action == AttendanceAction.checkIn) 'checkin_message': '',
        if (action == AttendanceAction.checkOut) 'checkout_message': '',
      };

      debugPrint('attendance/create body keys: ${body.keys.toList()}');

      final res = await Api.post(ApiUrls.attendanceCreate, body: body);

      if (_disposed) return;

      if (res.success) {
        onActionDone?.call(action);
      } else {
        actionError = res.message;
      }
    } catch (e, st) {
      debugPrint('attendance/create error: $e\n$st');
      actionError = 'Could not complete the action. Please try again.';
    } finally {
      if (!_disposed) {
        loadingAction = null;
        notifyListeners();
      }
    }

    if (_disposed) return;
    await getStatus(); // refresh so the buttons update
  }

  // ---------------- Status ----------------
  Future<void> getStatus() async {
    isStatusLoading = true;
    statusError = null;
    notifyListeners();

    try {
      final res = await Api.post(
        ApiUrls.employeeSetup,
        body: {
          'token': code,
          'client_id': '${ClientSession.clientDetail['id']}',
          'access_detail': 'false',
          'date': _formatDate(AppTime.now()),
        },
      );

      if (res.success) {
        final data = res.map['data'];
        if (data is Map) {
          statusData = Map<String, dynamic>.from(data);
          status = _parseStatus(statusData!);
          debugPrint('employee status data: $statusData'); // remove once keys are confirmed
        } else {
          statusError = 'Invalid response from server.';
        }
      } else {
        statusError = res.message;
      }
    } catch (e) {
      debugPrint('employee status error: $e');
      statusError = 'Could not load status. Please try again.';
    }

    if (_disposed) return;
    isStatusLoading = false;
    notifyListeners();
  }

  /// ASSUMPTION: the key names below are guesses. Adjust them once you
  /// see the real response from the employee status endpoint.
  AttendanceStatus _parseStatus(Map<String, dynamic> data) {
    final detail = data['attendanceDetail'];
    if (detail is! Map) return AttendanceStatus.notCheckedIn;

    bool flag(String key) {
      final v = detail[key];
      return v == 1 || v == true || v == '1';
    }

    // Check the latest step first
    if (flag('checkout')) return AttendanceStatus.checkedOut;
    if (flag('lunchout')) return AttendanceStatus.lunchDone;
    if (flag('lunchin')) return AttendanceStatus.onLunch;
    if (flag('checkin')) return AttendanceStatus.checkedIn;
    return AttendanceStatus.notCheckedIn;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    now.dispose();
    super.dispose();
  }
}