import 'dart:typed_data';

import '../../data/models/health_enums.dart';

/// Result of a single capture.
class CaptureResult {
  const CaptureResult({
    required this.bytes,
    required this.capturedAt,
    required this.source,
    required this.mimeType,
    this.width,
    this.height,
  });

  final Uint8List bytes;
  final DateTime capturedAt;
  final CaptureSource source;
  final String mimeType;
  final int? width;
  final int? height;

  int get sizeBytes => bytes.lengthInBytes;
}

/// Abstraction over the in-app camera so no UI widget talks to the `camera`
/// plugin directly. Implemented by [MockCameraService] (default, runnable) and
/// `DeviceCameraService` (real, behind the `camera` dependency).
abstract interface class CameraService {
  /// Whether a usable camera exists on this device.
  Future<bool> isAvailable();

  /// Open the in-app live camera and return the captured frame, or null if the
  /// user backed out.
  Future<CaptureResult?> capturePhoto();

  /// Pick from the gallery — only offered when the admin has enabled gallery
  /// uploads. Returns null if cancelled.
  Future<CaptureResult?> pickFromGallery();

  /// Release camera resources.
  Future<void> dispose();
}
