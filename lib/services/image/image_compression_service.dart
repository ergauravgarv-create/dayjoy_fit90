import 'dart:typed_data';

/// Compresses captured images without visible quality loss, and strips
/// unnecessary EXIF metadata (location, device) for privacy before upload.
abstract interface class ImageCompressionService {
  /// Returns a compressed copy of [input], bounded to [maxDimension] px on the
  /// long edge at roughly [quality] (0..100). Also strips EXIF when
  /// [stripExif] is true.
  Future<Uint8List> compress(
    Uint8List input, {
    int maxDimension = 1600,
    int quality = 82,
    bool stripExif = true,
  });
}

/// Runnable default: a pass-through so the app works without the `image`
/// package. Swap for `EncodedImageCompressionService` (below, guarded) in
/// production.
class PassthroughImageCompressionService implements ImageCompressionService {
  const PassthroughImageCompressionService();

  @override
  Future<Uint8List> compress(
    Uint8List input, {
    int maxDimension = 1600,
    int quality = 82,
    bool stripExif = true,
  }) async {
    // No-op in the mock build. The real implementation decodes, resizes to
    // maxDimension, re-encodes at `quality`, and drops EXIF.
    return input;
  }
}
