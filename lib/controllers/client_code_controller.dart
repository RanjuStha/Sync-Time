import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flexyear/utils/app_time.dart';
import 'package:flexyear/services/api_urls.dart';
import 'package:flexyear/services/api.dart';
import 'package:flexyear/services/app_prefs.dart';
import 'package:flexyear/services/client_session.dart';
import 'package:flexyear/services/client_setup_service.dart';

class ClientCodeController extends ChangeNotifier {
  ClientCodeController({this.onVerified}) {
    // Rebuild the button when the code text changes
    codeController.addListener(notifyListeners);

    // Live clock: ticks every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = AppTime.now();
    });
  }

  /// Called after the client is verified and saved (use it to navigate).
  final VoidCallback? onVerified;

  // ---------- Texts ----------
  final String codeLabel = 'Enter your client code';
  final String codeHint = 'Client Code';
  final String setupButtonText = 'Setup Client';

  // ---------- Live time / date ----------
  // Separate notifier so only the clock rebuilds every second
  final ValueNotifier<DateTime> now = ValueNotifier<DateTime>(AppTime.now());
  Timer? _timer;

  // ---------- Client code ----------
  final TextEditingController codeController = TextEditingController();

  String? _codeError;
  String? get codeError => _codeError;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _disposed = false;

  bool get canSetup => codeController.text.trim().isNotEmpty && !_isLoading;

  // Future<void> setupClient() async {
  //   if (!canSetup) return;
  //
  //   _codeError = null;
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final res = await Api.post(
  //       ApiUrls.clientSetup,
  //       body: {'token': codeController.text.trim(),
  //         'organization_id': AppPrefs.companyId}, // TODO: confirm field name
  //     );
  //
  //     if (res.success) {
  //       final data = res.map['data'];
  //       final detail = data is Map ? data['clientDetail'] : null;
  //
  //       if (detail is Map) {
  //         ClientSession.load(data); // <-- replaces the commented saveOrganization
  //         if (_disposed) return;
  //         _isLoading = false;
  //         notifyListeners();
  //         onVerified?.call();
  //         return;
  //       }
  //       _codeError = 'Invalid response from server.';
  //     } else {
  //       _codeError = res.message;
  //     }
  //   } catch (e) {
  //     _codeError = 'Something went wrong. Please try again.';
  //   }
  //
  //   if (_disposed) return;
  //   _isLoading = false;
  //   notifyListeners();
  // }


  Future<void> setupClient() async {
    if (!canSetup) return;

    _codeError = null;
    _isLoading = true;
    notifyListeners();

    final result = await ClientSetupService.setup(codeController.text);

    if (_disposed) return;
    _isLoading = false;

    if (result.success) {
      notifyListeners();
      onVerified?.call();
      return;
    }

    _codeError = result.error;
    notifyListeners();
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
    codeController.dispose();
    super.dispose();
  }
}