import 'package:flutter/material.dart';
import 'package:flexyear/controllers/pin_code_controller.dart';
import 'package:flexyear/models/client_person.dart';
import 'package:flexyear/utils/app_colors.dart';
import 'package:flexyear/services/app_prefs.dart';
import 'package:flexyear/utils/app_split_layout.dart';
import 'package:flexyear/utils/app_ui.dart';
import 'package:flexyear/views/attendance_view.dart';
import 'package:flexyear/views/language_sheet.dart';
import 'package:flexyear/views/reset_client_sheet.dart';
import 'package:flexyear/views/welcome_view.dart';

class PinCodeView extends StatefulWidget {
  const PinCodeView({
    super.key,
    this.companyName = 'Company Name',
    this.companyAddress = 'Company address, City, Country',
  });

  final String companyName;
  final String companyAddress;

  @override
  State<PinCodeView> createState() => _PinCodeViewState();
}

class _PinCodeViewState extends State<PinCodeView> {
  late final PinCodeController controller;

  @override
  void initState() {
    super.initState();
    controller = PinCodeController(
      companyName: widget.companyName,
      companyAddress: widget.companyAddress,
      onVerified: (person) {
        if (!mounted) return;
        LanguageSheet.show(
          context,
          userName: person.fullName,
          onSpanish: () {
            // TODO: switch app locale to Spanish
            _goToAttendance(person);
          },
          onEnglish: () {
            // TODO: switch app locale to English
            _goToAttendance(person);
          },
        );
      },
      onClientReset: _handleClientReset,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Clears the saved company and returns to the welcome screen.
  // Future<void> _handleClientReset() async {
  //   await AppPrefs.clearOrganization();
  //   if (!mounted) return;
  //   Navigator.of(context).pushAndRemoveUntil(
  //     MaterialPageRoute(builder: (_) => const WelcomeView()),
  //         (route) => false,
  //   );
  // }

  void _handleClientReset() {
    if (!mounted) return;
    setState(() {}); // rebuild with the newly saved client data
  }

  void _goToAttendance(ClientPerson person) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendanceView(
          userName: person.fullName,
          userId: (person.userId ?? person.id).toString(),
          type: person.type,
          code: person.code,
          userImageUrl: person.image,
          id: person.id,
        ),
      ),
    );
  }

  // void _showResetSheet() {
  //   ResetClientSheet.show(
  //     context,
  //     onVerify: controller.resetClient,
  //     onSuccess: controller.onClientReset,
  //   );
  // }

  void _showResetSheet() {
    ResetClientSheet.show(
      context,
      onVerify: controller.resetClient,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSplitLayout(
      left: (scale) => AppUI.clockSide(now: controller.now, scale: scale),
      compactHeader: (s, showImage) =>
          AppUI.clockHeader(showImage: showImage, scale: s),
      topAction: (scale) => AppUI.textButton(
        text: 'Reset Client?',
        icon: Icons.restart_alt,
        color: AppColors.danger,
        onPressed: _showResetSheet,
        scale: scale,
      ),
      content: _buildFormContent,
      footer: (scale) => AppUI.poweredBy(scale: scale),
      compactFooter: (s) => AppUI.dateTime(now: controller.now, scale: s * 0.8),
    );
  }

  Widget _buildFormContent(double scale) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppUI.heading(controller.companyName, scale: scale),
            AppUI.gap(4, scale),
            AppUI.caption(controller.companyAddress, scale: scale),
            AppUI.gap(32, scale),
            AppUI.label(controller.codeLabel, size: 16, bold: true, scale: scale),
            AppUI.gap(12, scale),
            AppUI.textField(
              context,
              controller: controller.pinController,
              hint: controller.pinHint,
              icon: Icons.pin,
              errorText: controller.pinError,
              keyboardType: TextInputType.number,
              obscure: true,
              digitsOnly: true,
              scale: scale,
            ),
            AppUI.gap(24, scale),
            AppUI.button(
              text: controller.verifyButtonText,
              onPressed: controller.canVerify ? controller.verifyPin : null,
              isLoading: controller.isLoading,
              scale: scale,
            ),
          ],
        );
      },
    );
  }
}