import 'dart:typed_data';

import '../../data/models/health_enums.dart';
import 'camera_service.dart';

/// Runnable stand-in for the device camera. Returns a small synthetic PNG so
/// the whole capture → compress → hash → upload pipeline can be exercised (and
/// tested) with no `camera` plugin and no real device.
class MockCameraService implements CameraService {
  MockCameraService({this.simulateCancel = false});

  /// When true, [capturePhoto] returns null to exercise the "user backed out"
  /// path.
  final bool simulateCancel;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<CaptureResult?> capturePhoto() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (simulateCancel) return null;
    return _synthetic(CaptureSource.liveCamera);
  }

  @override
  Future<CaptureResult?> pickFromGallery() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (simulateCancel) return null;
    return _synthetic(CaptureSource.gallery);
  }

  @override
  Future<void> dispose() async {}

  CaptureResult _synthetic(CaptureSource source) {
    // Vary the bytes a little by source so mock captures aren't all identical
    // duplicates in tests.
    final int seed = source == CaptureSource.liveCamera ? 7 : 11;
    final Uint8List bytes = Uint8List.fromList(
      List<int>.generate(2048, (i) => (i * seed) % 256),
    );
    return CaptureResult(
      bytes: bytes,
      capturedAt: DateTime.now(),
      source: source,
      mimeType: 'image/jpeg',
      width: 1080,
      height: 1440,
    );
  }
}
