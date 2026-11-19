import 'dart:io' show File, Platform;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flexyear/views/camera_capture_macos_view.dart';

/// Full-screen camera. Captures a photo, shows it, and returns
/// the image path (or null if cancelled).
class CameraCaptureView extends StatefulWidget {
  const CameraCaptureView({super.key, required this.title});

  final String title;

  static bool get _isNativeMacOS => !kIsWeb && Platform.isMacOS;

  static Future<String?> open(BuildContext context, {required String title}) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _isNativeMacOS
            ? CameraCaptureMacosView(title: title)
            : CameraCaptureView(title: title),
      ),
    );
  }

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<CameraCaptureView> {
  CameraController? _camera;
  String? _error;
  String? _capturedPath;
  bool _isCapturing = false;
  bool _isFrontCamera = false;

  /// iOS: `high` is a 16:9 video stream while photos use the full 4:3 sensor,
  /// so the preview looks zoomed in. `max` uses the native 4:3 format.
  ResolutionPreset get _preset {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return ResolutionPreset.max;
    }
    return ResolutionPreset.high;
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }

      // Prefer the front camera (selfie), fall back to the first one
      final selected = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selected,
        _preset,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _isFrontCamera = selected.lensDirection == CameraLensDirection.front;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.code == 'CameraAccessDenied'
            ? 'Camera permission denied. Please allow camera access in settings.'
            : 'Could not open the camera (${e.code}).';
      });
    } catch (e, st) {
      debugPrint('Camera init error: $e\n$st');
      if (!mounted) return;
      setState(() => _error = 'Could not open the camera.\n$e');
    }
  }

  Future<void> _capture() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final file = await cam.takePicture();
      if (!mounted) return;
      setState(() => _capturedPath = file.path);
    } on CameraException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not capture the photo. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final cam = _camera;
    if (cam == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final captured = _capturedPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Live preview OR captured image
        if (captured == null)
          _fullScreenPreview(cam)
        else
          _capturedImage(captured),

        // Buttons floating at the bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: captured == null
                  ? _captureButton()
                  : _reviewButtons(captured),
            ),
          ),
        ),
      ],
    );
  }

  /// Shows the full camera frame with no zoom or crop.
  /// CameraPreview already keeps the correct aspect ratio.
  Widget _fullScreenPreview(CameraController cam) {
    return Center(child: CameraPreview(cam));
  }

  /// Web gives a blob: URL, native gives a file path.
  /// Front-camera photos are flipped so they match the mirrored preview.
  Widget _capturedImage(String path) {
    final Widget image = kIsWeb
        ? Image.network(path, fit: BoxFit.contain)
        : Image.file(File(path), fit: BoxFit.contain);

    return Center(
      child: _isFrontCamera ? Transform.flip(flipX: true, child: image) : image,
    );
  }

  Widget _captureButton() {
    return GestureDetector(
      onTap: _capture,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white54, width: 6),
        ),
        child: _isCapturing
            ? const Padding(
          padding: EdgeInsets.all(22),
          child: CircularProgressIndicator(strokeWidth: 3),
        )
            : null,
      ),
    );
  }

  Widget _reviewButtons(String path) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _capturedPath = null),
            icon: const Icon(Icons.refresh),
            label: const Text('Retake'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black45,
              side: const BorderSide(color: Colors.white70),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(path),
            icon: const Icon(Icons.check),
            label: const Text('Use Photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}