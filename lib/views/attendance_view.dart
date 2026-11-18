import 'package:flutter/material.dart';
import 'package:flexyear/controllers/attendance_controller.dart';
import 'package:flexyear/utils/app_colors.dart';
import 'package:flexyear/utils/app_date_utils.dart';
import 'package:flexyear/utils/app_split_layout.dart';
import 'package:flexyear/utils/app_ui.dart';
import 'package:flexyear/views/camera_capture_view.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({
    super.key,
    required this.code,
    required this.userName,
    required this.userId,
    required this.userImageUrl,
    required this.type,
    required this.id,
  });

  final String code;
  final String userName;
  final String userId;
  final String? userImageUrl;
  final String? type;
  final int id;

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  late final AttendanceController controller;

  /// True while the camera screen is open, so a double tap
  /// can't push it twice.
  bool _isCameraOpen = false;

  @override
  void initState() {
    super.initState();
    controller = AttendanceController(
      code: widget.code,
      userName: widget.userName,
      userId: widget.userId,
      position: widget.type ?? 'Employee',
      userImageUrl: widget.userImageUrl,
      id: widget.id,
      onActionDone: (action) {
        if (!mounted) return;
        AppUI.snack(context, '${controller.labelFor(action)} successful');
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ============================================================
  // ACTION FLOW: open camera -> capture -> use photo -> perform
  // ============================================================
  Future<void> _onActionPressed(AttendanceAction action) async {
    if (_isCameraOpen) return;
    setState(() => _isCameraOpen = true);

    String? photoPath;
    try {
      photoPath = await CameraCaptureView.open(
        context,
        title: controller.labelFor(action),
      );
    } finally {
      if (mounted) setState(() => _isCameraOpen = false);
    }

    // User cancelled the camera, or left this screen
    if (photoPath == null || !mounted) return;

    await controller.perform(action, photoPath: photoPath);
  }

  @override
  Widget build(BuildContext context) {
    return AppSplitLayout(
      left: (scale) => AppUI.clockSide(now: controller.now, scale: scale),
      compactHeader: (s, showImage) =>
          AppUI.clockHeader(showImage: showImage, scale: s),
      topAction: (scale) => AppUI.textButton(
        text: controller.closeText,
        icon: Icons.close,
        color: AppColors.primary,
        onPressed: () => Navigator.of(context).pop(),
        scale: scale,
      ),
      content: _buildContent,
      footer: (scale) => AppUI.poweredBy(scale: scale),
      compactFooter: (s) => AppUI.dateTime(now: controller.now, scale: s * 0.8),
    );
  }

  // ============================================================
  // CONTENT: header + button grid
  // ============================================================
  Widget _buildContent(double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(scale),
        AppUI.gap(24, scale),
        _buildButtonGrid(scale),
      ],
    );
  }

  // ============================================================
  // HEADER: avatar + greeting + name + #ID . position
  // ============================================================
  Widget _buildHeader(double scale) {
    final radius = 32 * scale;
    final url = controller.userImageUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.white,
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null
              ? Icon(Icons.person, size: radius, color: Colors.black38)
              : null,
        ),
        AppUI.hGap(16, scale),
        Expanded(
          child: ValueListenableBuilder<DateTime>(
            valueListenable: controller.now,
            builder: (context, now, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppUI.caption(
                    AppDateUtils.greeting(now),
                    size: 14,
                    scale: scale,
                  ),
                  AppUI.gap(2, scale),
                  AppUI.label(
                    controller.userName,
                    size: 24,
                    bold: true,
                    maxLines: 1,
                    scale: scale,
                  ),
                  AppUI.gap(2, scale),
                  AppUI.caption(
                    controller.subtitle,
                    size: 13,
                    scale: scale,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 2 x 2 BUTTON GRID (+ error message)
  // ============================================================
  Widget _buildButtonGrid(double scale) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final gap = 12 * scale;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                mainAxisExtent: 72 * AppUI.soft(scale),
              ),
              children: [
                _actionButton(
                    AttendanceAction.checkIn, AppColors.success, scale),
                _actionButton(
                    AttendanceAction.startLunch, AppColors.warning, scale),
                _actionButton(
                    AttendanceAction.endLunch, AppColors.danger, scale),
                _actionButton(
                    AttendanceAction.checkOut, AppColors.primary, scale),
              ],
            ),

            // Errors from the status load or from the last action
            if (controller.actionError != null ||
                controller.statusError != null) ...[
              AppUI.gap(12, scale),
              Text(
                controller.actionError ?? controller.statusError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 13 * scale),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _actionButton(AttendanceAction action, Color color, double scale) {
    return AppUI.button(
      text: controller.labelFor(action),
      color: color,
      radius: 12,
      fontSize: 18,
      height: 72,
      isLoading: controller.loadingAction == action,
      // Other buttons are disabled while one action is running
      // or while the camera is open
      onPressed: controller.canDo(action) && !_isCameraOpen
          ? () => _onActionPressed(action)
          : null,
      scale: scale,
    );
  }
}