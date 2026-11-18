import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flexyear/utils/app_time.dart';
import 'package:flexyear/models/client_person.dart';
import 'package:flexyear/services/client_session.dart';
import 'client_code_controller.dart';
import 'package:flexyear/services/client_setup_service.dart';
import 'package:flexyear/services/app_prefs.dart';
import 'package:flexyear/services/client_setup_service.dart';

class PinCodeController extends ChangeNotifier {
  PinCodeController({
    required this.companyName,
    required this.companyAddress,
    this.onVerified,
    this.onClientReset,
  }) {
    pinController.addListener(_onPinChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = AppTime.now();
    });
  }

  /// Called with the matched person after a successful verify.
  final void Function(ClientPerson person)? onVerified;
  final VoidCallback? onClientReset;

  final String companyName;
  final String companyAddress;
  String? refreshError;
  String? resetError;

  // ---------------- Texts ----------------
  final String codeLabel = 'Enter Your PIN Code';
  final String pinHint = 'PIN Code';
  final String verifyButtonText = 'Verify PIN & Process';

  // ---------------- State ----------------
  final TextEditingController pinController = TextEditingController();
  final ValueNotifier<DateTime> now = ValueNotifier(AppTime.now());
  Timer? _timer;

  bool isLoading = false;
  String? pinError;

  ClientPerson? _person;
  ClientPerson? get person => _person;

  bool _disposed = false;

  bool get canVerify => pinController.text.trim().isNotEmpty && !isLoading;

  void _onPinChanged() {
    // Clear stale result/error as soon as the user edits the PIN
    if (_person != null || pinError != null) {
      _person = null;
      pinError = null;
    }
    notifyListeners();
  }

  // ---------------- Verify PIN ----------------
  Future<void> verifyPin() async {
    if (!canVerify) return;
    isLoading = true;
    pinError = null;
    _person = null;
    notifyListeners();

    try {
      final refreshed = await refreshClient();
      if (!refreshed) {
        pinError = refreshError ?? 'Could not refresh client data.';
        return; // finally block still resets isLoading
      }

      final match = ClientSession.findByCode(pinController.text);
      if (match == null) {
        pinError = 'Invalid PIN. Please try again.';
      } else {
        _person = match;
        onVerified?.call(match);
      }
    } catch (_) {
      pinError = 'Something went wrong. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // // ---------------- Reset client ----------------
  // Future<bool> resetClient(String clientCode) async {
  //   try {
  //     // TODO: call your reset-client API with clientCode
  //     await Future.delayed(const Duration(seconds: 1));
  //     return true;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  /// Re-fetches client data using the token saved in prefs.
  Future<bool> refreshClient() async {
    final result = await ClientSetupService.setupFromSavedToken();
    refreshError = result.error;
    return result.success;
  }

// ---------------- Reset client ----------------
//   Future<bool> resetClient(String clientCode) async {
//     try {
//       // TODO: call your reset-client API with clientCode
//       await Future.delayed(const Duration(seconds: 1));
//       await AppPrefs.clearClientToken(); // if reset should forget the client
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

  /// Returns null on success, or an error message on failure.
  Future<String?> resetClient(String clientCode) async {
    final result = await ClientSetupService.setup(clientCode);
    if (!result.success) return result.error ?? 'Invalid client code.';

    clear();
    onClientReset?.call();
    return null;
  }

  void clear() {
    pinController.clear(); // listener resets person/error
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    pinController.removeListener(_onPinChanged);
    pinController.dispose();
    now.dispose();
    super.dispose();
  }
}