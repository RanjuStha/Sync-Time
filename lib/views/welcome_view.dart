import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flexyear/controllers/welcome_controller.dart';
import 'package:flexyear/utils/app_colors.dart';
import 'package:flexyear/utils/app_ui.dart';
import 'package:flexyear/views/client_code_view.dart';
import 'package:flexyear/services/app_prefs.dart';
import 'package:flexyear/views/pin_code_view.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  late final WelcomeController controller;

  /// Below this width we switch to a stacked (single column) layout.
  static const double _compactBreakpoint = 600;

  @override
  void initState() {
    super.initState();
    controller = WelcomeController(
      onVerified: () {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientCodeView(
              companyName: AppPrefs.companyName,
              companyAddress: AppPrefs.companyAddress,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Height of the on-screen keyboard (0 when hidden)
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      // The body is not squeezed by the keyboard; the form handles it itself.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < _compactBreakpoint;
            final scale = AppUI.scaleFor(constraints.maxWidth);

            return isCompact
                ? _buildCompact(constraints, scale, keyboard)
                : _buildWide(constraints, scale, keyboard);
          },
        ),
      ),
    );
  }

  // ============================================================
  // WIDE LAYOUT  (left 40% / right 60%)
  // ============================================================
  Widget _buildWide(
      BoxConstraints constraints,
      double scale,
      double keyboard,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------- LEFT SIDE (40%) ----------------
        Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.all(16 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppUI.logo(scale: scale),
                AppUI.gap(16, scale),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/illustration.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                AppUI.gap(16, scale),
                _buildCopyright(scale),
              ],
            ),
          ),
        ),

        // ---------------- RIGHT SIDE (60%) ----------------
        Expanded(
          flex: 6,
          child: Container(
            margin: EdgeInsets.only(left: 20 * scale),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final padding = 24 * scale;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    padding,
                    padding,
                    padding + keyboard, // room to scroll above the keyboard
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, box.maxHeight - (padding * 2)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildFormContent(scale),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMPACT LAYOUT  (stacked, scrollable, edge to edge)
  // ============================================================
  Widget _buildCompact(
      BoxConstraints constraints,
      double scale,
      double keyboard,
      ) {
    final s = scale.clamp(0.9, 1.2).toDouble();
    // Hide the big illustration on very short screens
    final showIllustration = constraints.maxHeight > 560;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: keyboard), // room above the keyboard
      child: ConstrainedBox(
        // Grey area always reaches the bottom of the screen
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: ColoredBox(
          color: AppColors.panel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // White header (logo + illustration)
              ColoredBox(
                color: AppColors.white,
                child: Padding(
                  padding: EdgeInsets.all(16 * s),
                  child: Column(
                    children: [
                      AppUI.logo(height: 56, scale: s),
                      if (showIllustration) ...[
                        AppUI.gap(12, s),
                        Image.asset(
                          'assets/images/illustration.png',
                          height: (constraints.maxHeight * 0.25)
                              .clamp(120.0, 260.0),
                          fit: BoxFit.contain,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Grey form area, edge to edge
              Padding(
                padding: EdgeInsets.all(20 * s),
                child: _buildFormContent(s),
              ),

              Padding(
                padding: EdgeInsets.only(bottom: 20 * s),
                child: Center(child: _buildCopyright(s)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyright(double scale) {
    return AppUI.caption(
      controller.copyright,
      align: TextAlign.center,
      scale: AppUI.soft(scale),
    );
  }

  // ============================================================
  // FORM CONTENT (shared by both layouts)
  // ============================================================
  Widget _buildFormContent(double scale) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step label (always visible)
            AppUI.label(
              controller.stepLabel,
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
              scale: scale,
            ),
            AppUI.gap(16, scale),
            if (controller.isStepOne)
              _buildStepOne(scale)
            else
              _buildStepTwo(context, scale),
          ],
        );
      },
    );
  }

  // ---------------- STEP 1 ----------------
  Widget _buildStepOne(double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: AppUI.label(
                controller.greeting,
                size: 18,
                weight: FontWeight.w500,
                scale: scale,
              ),
            ),
            AppUI.hGap(8, scale),
            Icon(Icons.waving_hand, color: Colors.amber, size: 22 * scale),
          ],
        ),
        AppUI.gap(8, scale),
        AppUI.heading(controller.title, scale: scale),
        AppUI.gap(8, scale),
        AppUI.label(controller.subtitle, size: 15, scale: scale),
        AppUI.gap(24, scale),
        AppUI.button(
          text: controller.buttonText,
          onPressed: controller.getStarted,
          scale: scale,
        ),
      ],
    );
  }

  // ---------------- STEP 2 ----------------
  Widget _buildStepTwo(BuildContext context, double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppUI.label(
          controller.codeLabel,
          size: 22,
          bold: true,
          scale: scale,
        ),
        AppUI.gap(16, scale),
        AppUI.textField(
          context,
          controller: controller.codeController,
          hint: controller.codeHint,
          icon: Icons.apartment,
          errorText: controller.codeError,
          keyboardType: TextInputType.number,
          digitsOnly: true,
          scale: scale,
        ),
        AppUI.gap(24, scale),
        AppUI.button(
          text: controller.verifyButtonText,
          onPressed: controller.canVerify ? controller.verifyCode : null,
          isLoading: controller.isLoading,
          scale: scale,
        ),
      ],
    );
  }
}