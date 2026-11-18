import 'dart:ui' show FontFeature;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flexyear/utils/app_colors.dart';
import 'package:flexyear/utils/app_date_utils.dart';

/// Global UI helpers. Call them as AppUI.button(...), AppUI.label(...), etc.
/// Most take a [scale] so everything grows/shrinks with the screen.
class AppUI {
  AppUI._();

  // ============================================================
  // SCALE / LAYOUT
  // ============================================================

  /// Scale factor from screen width (0.8x - 1.2x).
  static double scaleFor(double width) =>
      (width / 1000).clamp(0.8, 1.2).toDouble();

  /// Softer scale (0.9x - 1.1x) for buttons, icons and small text.
  static double soft(double scale) => scale.clamp(0.9, 1.1).toDouble();

  static Widget gap(double size, [double scale = 1]) =>
      SizedBox(height: size * scale);

  static Widget hGap(double size, [double scale = 1]) =>
      SizedBox(width: size * scale);

  // ============================================================
  // LABELS
  // ============================================================
  static Widget label(
      String text, {
        double size = 14,
        bool bold = false,
        FontWeight? weight,
        Color color = AppColors.textPrimary,
        TextAlign? align,
        int? maxLines,
        double scale = 1,
      }) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: size * scale,
        fontWeight: weight ?? (bold ? FontWeight.bold : FontWeight.normal),
        color: color,
      ),
    );
  }

  /// Big bold heading (e.g. company name).
  static Widget heading(String text,
      {double size = 26,
        Color color = AppColors.textPrimary,
        double scale = 1}) =>
      label(text, size: size, bold: true, color: color, scale: scale);

  /// Small grey text (e.g. address, copyright).
  static Widget caption(String text,
      {double size = 12, TextAlign? align, double scale = 1}) =>
      label(text,
          size: size,
          color: AppColors.textSecondary,
          align: align,
          scale: scale);

  // ============================================================
  // BUTTONS
  // ============================================================

  /// Filled button. Shows a spinner while [isLoading] is true.
  static Widget button({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color color = AppColors.primary,
    Color textColor = Colors.white,
    IconData? icon,
    Widget? leading, // e.g. a flag emoji Text; wins over [icon]
    double height = 48,
    double fontSize = 15,
    double radius = 8,
    bool fullWidth = true,
    double scale = 1,
  }) {
    final k = soft(scale);
    final lead = leading ??
        (icon != null ? Icon(icon, size: 20 * k) : null);

    final content = isLoading
        ? SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
    )
        : FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lead != null) ...[lead, SizedBox(width: 8 * k)],
          Text(text, style: TextStyle(fontSize: fontSize * scale)),
        ],
      ),
    );

    final btn = SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height * k,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          disabledForegroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: content,
      ),
    );
    return btn;
  }

  /// Outlined button (e.g. "Switch To Spanish").
  static Widget outlinedButton({
    required String text,
    required VoidCallback? onPressed,
    Widget? leading,
    Color color = AppColors.textPrimary,
    double height = 48,
    double radius = 8,
    double scale = 1,
  }) {
    final k = soft(scale);
    return SizedBox(
      width: double.infinity,
      height: height * k,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading, SizedBox(width: 8 * k)],
              Text(text),
            ],
          ),
        ),
      ),
    );
  }

  /// Text-only button with optional icon (e.g. "Reset Client?").
  static Widget textButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    Color color = AppColors.primary,
    double fontSize = 14,
    double scale = 1,
  }) {
    final k = soft(scale);
    final label = Text(
      text,
      style: TextStyle(fontSize: fontSize * k, fontWeight: FontWeight.w600),
    );
    final style = TextButton.styleFrom(foregroundColor: color);

    if (icon == null) {
      return TextButton(onPressed: onPressed, style: style, child: label);
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18 * k),
      label: label,
      style: style,
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================
  static Widget textField(
      BuildContext context, {
        required TextEditingController controller,
        required String hint,
        IconData? icon,
        String? errorText,
        TextInputType? keyboardType,
        bool obscure = false,
        bool digitsOnly = false,
        bool autofocus = false,
        int? maxLength,
        Color fillColor = Colors.white,
        ValueChanged<String>? onChanged,
        ValueChanged<String>? onSubmitted,
        double scale = 1,
      }) {
    // Keeps the field visible above the on-screen keyboard
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      autofocus: autofocus,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: [if (digitsOnly) FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(fontSize: 16 * scale),
      scrollPadding: EdgeInsets.only(bottom: keyboard + 90),
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon) : null,
        hintText: hint,
        errorText: errorText,
        counterText: '',
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ============================================================
  // SPINNER
  // ============================================================
  static Widget spinner({
    double size = 24,
    Color color = AppColors.primary,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  // ============================================================
  // CLOCK SIDE (logo + watch image + time/date), used on 3 screens
  // ============================================================
  static Widget clockSide({
    required ValueListenable<DateTime> now,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logo(scale: scale),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: clockImage(scale: scale),
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: dateTime(now: now, scale: scale),
        ),
      ],
    );
  }

  /// Narrow-screen header: logo + watch image (hidden on short screens).
  static Widget clockHeader({required bool showImage, required double scale}) {
    return Column(
      children: [
        logo(height: 56, scale: scale),
        if (showImage) ...[
          gap(16, scale),
          clockImage(scale: scale * 0.8),
        ],
      ],
    );
  }

  // ============================================================
  // IMAGES / BRANDING
  // ============================================================
  static Widget logo({double height = 80, double scale = 1}) => Image.asset(
    'assets/images/logo.png',
    height: height * scale,
  );

  static Widget clockImage({double scale = 1}) => Image.asset(
    'assets/images/time.png',
    height: 200 * scale,
    fit: BoxFit.contain,
  );

  static Widget poweredBy({double scale = 1}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        caption('Powered By', scale: soft(scale)),
        SizedBox(width: 8 * scale),
        Image.asset('assets/images/logo.png', height: 32 * scale),
      ],
    );
  }

  // ============================================================
  // LIVE TIME + DATE
  // ============================================================
  static Widget dateTime({
    required ValueListenable<DateTime> now,
    double scale = 1,
  }) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: now,
      builder: (context, t, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppDateUtils.formatTime(t),
              style: TextStyle(
                fontSize: 40 * scale,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              AppDateUtils.formatDate(t),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18 * scale,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BOTTOM SHEET + SNACKBAR
  // ============================================================
  static Future<T?> showSheet<T>(
      BuildContext context, {
        required WidgetBuilder builder,
        bool dismissible = true,
      }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: builder,
    );
  }

  static void snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}