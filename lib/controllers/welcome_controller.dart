import 'package:flutter/material.dart';
import 'package:flexyear/services/api.dart';
import 'package:flexyear/services/api_urls.dart';
import 'package:flexyear/services/app_prefs.dart';

class WelcomeController extends ChangeNotifier {
  WelcomeController({this.onVerified}) {
    // Rebuild the view whenever the code text changes
    codeController.addListener(notifyListeners);
  }

  /// Called after the company code is verified (use it to navigate).
  /// Receives the response data so the next screen can show real values.
  final VoidCallback? onVerified;

  // ---------- Step ----------
  int _currentStep = 1;
  final int totalSteps = 2;

  int get currentStep => _currentStep;
  bool get isStepOne => _currentStep == 1;
  bool get isStepTwo => _currentStep == 2;
  String get stepLabel => 'Step $_currentStep/$totalSteps';

  // ---------- Step 1 texts ----------
  final String greeting = 'Hey';
  final String title = 'Welcome to Sync Time!';
  final String subtitle =
      'First setup your organization\'s detail to get inside this system';
  final String buttonText = "Let's Get Started";

  // ---------- Step 2 texts ----------
  final String codeLabel = 'Enter Your Company Code';
  final String codeHint = 'Type Code Here';
  final String verifyButtonText = 'Verify and process';

  // ---------- Common ----------
  final String copyright = '2026 | Copyright Owned By Sync Time';

  // ---------- Company code ----------
  final TextEditingController codeController = TextEditingController();
  String? _codeError;
  String? get codeError => _codeError;

  // ---------- State ----------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// True when a code is typed and nothing is loading
  bool get canVerify =>
      codeController.text.trim().isNotEmpty && !_isLoading;

  /// Step 1 -> Step 2
  void getStarted() {
    _currentStep = 2;
    notifyListeners();
  }

  /// Step 2: verify the company code
  Future<void> verifyCode() async {
    if (!canVerify) return;

    _codeError = null;
    _isLoading = true;
    notifyListeners();

    final res = await Api.post(
      ApiUrls.organizationSetup,
      body: {'token': codeController.text.trim()}, // TODO: your field name
    );

    if (res.success) {
      // Response: { data: { organizationDetail: { name, address, ... } } }
      final data = res.map['data'];
      final detail = data is Map ? data['organizationDetail'] : null;

      if (detail is Map) {
        await AppPrefs.saveOrganization(detail);
        _isLoading = false;
        notifyListeners();
        onVerified?.call();
        return;
      }
      _codeError = 'Invalid response from server.';
    } else {
      _codeError = res.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}