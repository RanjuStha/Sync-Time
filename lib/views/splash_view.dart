import 'package:flutter/material.dart';
import 'package:flexyear/controllers/splash_controller.dart';
import 'package:flexyear/utils/app_colors.dart';
import 'package:flexyear/services/app_prefs.dart';
import 'package:flexyear/utils/app_ui.dart';
import 'welcome_view.dart';
import 'pin_code_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashController controller = SplashController();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await controller.initApp();
    if (!mounted) return;

    final Widget next = AppPrefs.hasCompany
        ? PinCodeView(
      companyName: AppPrefs.companyName.isNotEmpty
          ? AppPrefs.companyName
          : 'Company Name',
      companyAddress: AppPrefs.companyAddress.isNotEmpty
          ? AppPrefs.companyAddress
          : 'Company address, City, Country',
    )
        : const WelcomeView();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortest = constraints.biggest.shortestSide;
            final logoHeight = (shortest * 0.30).clamp(60.0, 200.0);
            final spinnerSize = (logoHeight * 0.3).clamp(20.0, 40.0);
            final gap = (logoHeight * 0.3).clamp(12.0, 40.0);

            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppUI.logo(height: logoHeight),
                    AppUI.gap(gap),
                    SizedBox(
                      width: spinnerSize,
                      height: spinnerSize,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}