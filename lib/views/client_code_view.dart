import 'package:flutter/material.dart';
import 'package:flexyear/controllers/client_code_controller.dart';
import 'package:flexyear/services/app_prefs.dart';
import 'package:flexyear/utils/app_colors.dart';
import 'package:flexyear/utils/app_split_layout.dart';
import 'package:flexyear/utils/app_ui.dart';
import 'pin_code_view.dart';

class ClientCodeView extends StatefulWidget {
  const ClientCodeView({
    super.key,
    this.companyName,
    this.companyAddress,
  });


  /// Optional overrides. If null, the saved preferences are used.
  final String? companyName;
  final String? companyAddress;

  @override
  State<ClientCodeView> createState() => _ClientCodeViewState();
}

class _ClientCodeViewState extends State<ClientCodeView> {
  late final ClientCodeController controller;

  // Organization data shown in the header (read from prefs / overrides)
  late final String _name;
  late final String _address;
  late final String _image;

  @override
  void initState() {
    super.initState();

    _name = _resolveName();
    _address = _resolveAddress();
    _image = AppPrefs.companyImage;

    controller = ClientCodeController(onVerified: _onVerified);
  }

  String _resolveName() =>
      widget.companyName ??
          (AppPrefs.companyName.isNotEmpty ? AppPrefs.companyName : 'Company Name');

  String _resolveAddress() =>
      widget.companyAddress ??
          (AppPrefs.companyAddress.isNotEmpty
              ? AppPrefs.companyAddress
              : 'Company address, City, Country');

  /// Called after the code is verified and the organization is saved.
  /// Re-read prefs here so the next screen gets the freshly saved data.
  void _onVerified() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinCodeView(
          companyName: _resolveName(),
          companyAddress: _resolveAddress(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSplitLayout(
      left: (scale) => AppUI.clockSide(now: controller.now, scale: scale),
      compactHeader: (s, showImage) =>
          AppUI.clockHeader(showImage: showImage, scale: s),
      content: _buildFormContent,
      footer: (scale) => AppUI.poweredBy(scale: scale),
      compactFooter: (s) => AppUI.dateTime(now: controller.now, scale: s * 0.8),
    );
  }

  // ============================================================
  // COMPANY HEADER (image + name + address)
  // ============================================================
  Widget _buildCompanyHeader(double scale) {
    final size = 56 * scale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_image.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: size,
              height: size,
              color: AppColors.white,
              child: Image.network(
                _image,
                fit: BoxFit.contain,
                // Fall back to an icon if the image fails to load
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.business, size: size * 0.6, color: Colors.black38),
              ),
            ),
          ),
          AppUI.hGap(16, scale),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppUI.heading(_name, scale: scale),
              AppUI.gap(4, scale),
              AppUI.caption(_address, scale: scale),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORM CONTENT
  // ============================================================
  Widget _buildFormContent(double scale) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company image + name + address (from preferences)
            _buildCompanyHeader(scale),
            AppUI.gap(32, scale),

            // Enter your client code (bold)
            AppUI.label(controller.codeLabel, size: 16, bold: true, scale: scale),
            AppUI.gap(12, scale),

            AppUI.textField(
              context,
              controller: controller.codeController,
              hint: controller.codeHint,
              icon: Icons.apartment,
              scale: scale,
            ),

            // Show the API error (the controller sets codeError)
            if (controller.codeError != null) ...[
              AppUI.gap(8, scale),
              Text(
                controller.codeError!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13 * scale,
                ),
              ),
            ],
            AppUI.gap(24, scale),

            // Setup Client button
            AppUI.button(
              text: controller.setupButtonText,
              onPressed: controller.canSetup ? controller.setupClient : null,
              isLoading: controller.isLoading,
              scale: scale,
            ),
          ],
        );
      },
    );
  }
}