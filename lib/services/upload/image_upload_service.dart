import 'dart:typed_data';

/// Uploads image bytes to cloud storage and returns the download URL.
/// Reports progress so the UI can show a progress bar and failure states.
abstract interface class ImageUploadService {
  /// Uploads [bytes] to a storage path derived from [storageKey].
  /// [onProgress] receives 0..1. Throws on failure so the caller can retry /
  /// re-queue.
  Future<String> upload(
    Uint8List bytes, {
    required String storageKey,
    required String mimeType,
    void Function(double progress)? onProgress,
  });
}

/// Runnable mock: simulates a chunked upload with progress callbacks and an
/// optional forced failure (for testing the offline-queue retry path).
class MockImageUploadService implements ImageUploadService {
  MockImageUploadService({this.failTimes = 0});

  /// Number of leading calls that should throw before succeeding.
  int failTimes;

  @override
  Future<String> upload(
    Uint8List bytes, {
    required String storageKey,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    for (int i = 1; i <= 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      onProgress?.call(i / 10);
    }
    if (failTimes > 0) {
      failTimes--;
      throw const UploadException('Simulated network failure');
    }
    return 'https://mock.storage/dayjoy/$storageKey';
  }
}

class UploadException implements Exception {
  const UploadException(this.message);
  final String message;
  @override
  String toString() => 'UploadException: $message';
}
