import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flexyear/utils/app_colors.dart';
import 'package:flexyear/utils/app_ui.dart';

typedef ScaleBuilder = Widget Function(double scale);

/// Shared screen layout: left 40% / right 60% on wide screens,
/// a stacked scrollable page on narrow screens. Handles the keyboard.
class AppSplitLayout extends StatelessWidget {
  const AppSplitLayout({
    super.key,
    required this.left,
    required this.content,
    required this.compactHeader,
    this.topAction,
    this.footer,
    this.compactFooter,
    this.breakpoint = 600,
  });

  /// Whole left side (wide layout).
  final ScaleBuilder left;

  /// Main content of the grey panel (the form).
  final ScaleBuilder content;

  /// White header on narrow screens. [showImage] is false on short screens.
  final Widget Function(double scale, bool showImage) compactHeader;

  /// Top-right button of the panel (e.g. "Reset Client?").
  final ScaleBuilder? topAction;

  /// Pinned to the bottom of the panel (e.g. "Powered By").
  final ScaleBuilder? footer;

  /// Extra bottom block on narrow screens only (e.g. time/date, copyright).
  final ScaleBuilder? compactFooter;

  /// Below this width the stacked layout is used.
  final double breakpoint;

  static const double _bottomMargin = 20;

  @override
  Widget build(BuildContext context) {
    // Height of the on-screen keyboard (0 when hidden)
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      // The body is not squeezed by the keyboard; the panel handles it.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = AppUI.scaleFor(constraints.maxWidth);
            return constraints.maxWidth < breakpoint
                ? _compact(constraints, scale, keyboard)
                : _wide(scale, keyboard);
          },
        ),
      ),
    );
  }

  // ---------------- WIDE ----------------
  Widget _wide(double scale, double keyboard) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16 * scale,
              16 * scale,
              16 * scale,
              _bottomMargin,
            ),
            child: left(scale),
          ),
        ),
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
                    padding + keyboard,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, box.maxHeight - (padding * 2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (topAction != null) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: topAction!(scale),
                              ),
                              AppUI.gap(8, scale),
                            ],
                            content(scale),
                          ],
                        ),
                        if (footer != null) ...[
                          AppUI.gap(24, scale),
                          Center(child: footer!(scale)),
                        ],
                      ],
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

  // ---------------- COMPACT ----------------
  Widget _compact(BoxConstraints constraints, double scale, double keyboard) {
    final s = scale.clamp(0.9, 1.2).toDouble();
    final showImage = constraints.maxHeight > 560;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        // Grey area always reaches the bottom of the screen
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: ColoredBox(
          color: AppColors.panel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: AppColors.white,
                child: Padding(
                  padding: EdgeInsets.all(16 * s),
                  child: compactHeader(s, showImage),
                ),
              ),
              if (topAction != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(20 * s, 8 * s, 20 * s, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: topAction!(s),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(20 * s, 8 * s, 20 * s, 20 * s),
                child: content(s),
              ),
              if (footer != null) Center(child: footer!(s)),
              if (compactFooter != null) ...[
                AppUI.gap(16, s),
                Center(child: compactFooter!(s)),
              ],
              const SizedBox(height: _bottomMargin),
            ],
          ),
        ),
      ),
    );
  }
}