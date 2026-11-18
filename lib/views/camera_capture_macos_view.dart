import 'dart:io';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/material.dart';

/// macOS camera screen. Returns the saved image path, or null if cancelled.
class CameraCaptureMacosView extends StatefulWidget {
  const CameraCaptureMacosView({super.key, required this.title});

  final String title;

  @override
  State<CameraCaptureMacosView> createState() => _CameraCaptureMacosViewState();
}

class _CameraCaptureMacosViewState extends State<CameraCaptureMacosView> {
  CameraMacOSController? _camera;
  String? _capturedPath;
  bool _isCapturing = false;

  Future<void> _capture() async {
    final cam = _camera;
    if (cam == null || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final photo = await cam.takePicture();
      final bytes = photo?.bytes;
      if (bytes == null) throw Exception('No image data');

      // Save to a temp file so the rest of the app can use a path
      final dir = await Directory.systemTemp.createTemp('attendance_');
      final file = File(
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      setState(() => _capturedPath = file.path);
    } catch (_) {
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
    _camera?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captured = _capturedPath;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: captured == null
                ? CameraMacOSView(
              fit: BoxFit.contain,
              cameraMode: CameraMacOSMode.photo,
              enableAudio: false,
              onCameraInizialized: (controller) {
                setState(() => _camera = controller);
              },
            )
                : Center(
              child: Image.file(File(captured), fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: captured == null ? _captureButton() : _reviewButtons(captured),
          ),
        ],
      ),
    );
  }

  Widget _captureButton() {
    return ElevatedButton.icon(
      onPressed: _camera == null || _isCapturing ? null : _capture,
      icon: _isCapturing
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.camera_alt),
      label: const Text('Capture'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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