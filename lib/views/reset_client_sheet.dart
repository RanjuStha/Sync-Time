import 'package:flutter/material.dart';
import 'package:flexyear/utils/app_colors.dart';
import 'package:flexyear/utils/app_ui.dart';

class ResetClientSheet extends StatefulWidget {
  const ResetClientSheet({
    super.key,
    required this.onVerify,
    this.onSuccess,
  });

  /// Called with the entered client code. Return true if the reset succeeded.
  /// Called with the entered client code. Return null on success, or an error message.
  final Future<String?> Function(String clientCode) onVerify;
  /// Called after the sheet closes following a successful reset.
  final VoidCallback? onSuccess;

  /// Shows the sheet as a modal bottom sheet.
  static Future<void> show(
      BuildContext context, {
        required Future<String?> Function(String clientCode) onVerify,
        VoidCallback? onSuccess,
      }) {
    return AppUI.showSheet<void>(
      context,
      builder: (_) => ResetClientSheet(
        onVerify: onVerify,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<ResetClientSheet> createState() => _ResetClientSheetState();
}

class _ResetClientSheetState extends State<ResetClientSheet> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  bool get _canVerify => _codeController.text.trim().isNotEmpty && !_isLoading;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      if (mounted) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Future<void> _verify() async {
  //   if (!_canVerify) return;
  //   setState(() {
  //     _isLoading = true;
  //     _error = null;
  //   });
  //
  //   final ok = await widget.onVerify(_codeController.text.trim());
  //   if (!mounted) return;
  //
  //   if (ok) {
  //     Navigator.of(context).pop();
  //     widget.onSuccess?.call();
  //   } else {
  //     setState(() {
  //       _isLoading = false;
  //       _error = 'Invalid client code. Please try again.';
  //     });
  //   }
  // }

  Future<void> _verify() async {
    if (!_canVerify) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final error = await widget.onVerify(_codeController.text.trim());
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
      widget.onSuccess?.call();
    } else {
      setState(() {
        _isLoading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lifts the sheet above the keyboard
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title: bold red
          AppUI.label(
            'Client Reset Confirmation',
            size: 20,
            bold: true,
            color: AppColors.danger,
          ),
          AppUI.gap(8),
          AppUI.label(
            'Please enter your client code to confirm resetting your client?',
          ),
          AppUI.gap(16),

          // Client code field with building icon
          AppUI.textField(
            context,
            controller: _codeController,
            hint: 'Client Code',
            icon: Icons.apartment,
            errorText: _error,
            autofocus: true,
            fillColor: AppColors.panel,
          ),
          AppUI.gap(20),

          // Cancel (red) + Verify Code (green)
          Row(
            children: [
              Expanded(
                child: AppUI.button(
                  text: 'Cancel',
                  color: AppColors.danger,
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                ),
              ),
              AppUI.hGap(12),
              Expanded(
                child: AppUI.button(
                  text: 'Verify Code',
                  color: AppColors.success,
                  onPressed: _canVerify ? _verify : null,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}