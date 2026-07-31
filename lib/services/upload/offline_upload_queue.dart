import 'dart:async';
import 'dart:typed_data';

import '../../data/models/health_enums.dart';
import '../../data/models/photo_submission.dart';
import 'image_upload_service.dart';

/// Persists the bytes for a queued upload. In-memory by default; back it with
/// the device filesystem (path_provider) in production so the queue survives
/// app restarts.
abstract interface class UploadByteStore {
  Future<void> put(String id, Uint8List bytes);
  Future<Uint8List?> get(String id);
  Future<void> remove(String id);
}

class InMemoryByteStore implements UploadByteStore {
  final Map<String, Uint8List> _bytes = {};
  @override
  Future<void> put(String id, Uint8List bytes) async => _bytes[id] = bytes;
  @override
  Future<Uint8List?> get(String id) async => _bytes[id];
  @override
  Future<void> remove(String id) async => _bytes.remove(id);
}

/// Queues photo uploads locally when connectivity is unavailable and
/// automatically retries when it returns. An activity is only marked complete
/// once the backend confirms the upload — callers await [enqueue]'s returned
/// future resolving to an `uploaded` submission, or listen to [changes].
class OfflineUploadQueue {
  OfflineUploadQueue({
    required ImageUploadService uploader,
    UploadByteStore? byteStore,
    this.maxAttempts = 5,
  })  : _uploader = uploader,
        _byteStore = byteStore ?? InMemoryByteStore();

  final ImageUploadService _uploader;
  final UploadByteStore _byteStore;
  final int maxAttempts;

  final List<PhotoSubmission> _queue = [];
  final _controller = StreamController<List<PhotoSubmission>>.broadcast();

  bool _online = true;
  bool _processing = false;

  Stream<List<PhotoSubmission>> get changes => _controller.stream;
  List<PhotoSubmission> get pending =>
      List.unmodifiable(_queue.where((s) => s.uploadStatus != UploadStatus.uploaded));

  /// Toggle connectivity. Call from a connectivity listener; passing true
  /// kicks off processing of anything queued while offline.
  void setOnline(bool online) {
    _online = online;
    if (online) unawaited(processPending());
  }

  /// Add a submission and (if online) attempt it immediately. Returns the
  /// final state of the submission (uploaded, or still queued/failed if
  /// offline / exhausted).
  Future<PhotoSubmission> enqueue(
    PhotoSubmission submission,
    Uint8List bytes,
  ) async {
    await _byteStore.put(submission.id, bytes);
    _queue.add(submission.copyWith(uploadStatus: UploadStatus.queued));
    _emit();
    if (_online) await processPending();
    return _queue.firstWhere((s) => s.id == submission.id);
  }

  /// Try to upload everything not yet uploaded, oldest first, with a bounded
  /// attempt count and linear backoff.
  Future<void> processPending() async {
    if (_processing || !_online) return;
    _processing = true;
    try {
      for (int i = 0; i < _queue.length; i++) {
        final PhotoSubmission s = _queue[i];
        if (s.uploadStatus == UploadStatus.uploaded) continue;
        if (s.attempts >= maxAttempts) continue;

        final Uint8List? bytes = await _byteStore.get(s.id);
        if (bytes == null) {
          _queue[i] = s.copyWith(
            uploadStatus: UploadStatus.failed,
            error: 'Bytes missing from store',
          );
          continue;
        }

        _queue[i] = s.copyWith(uploadStatus: UploadStatus.uploading);
        _emit();
        try {
          final String url = await _uploader.upload(
            bytes,
            storageKey: '${s.taskKey}/${s.id}',
            mimeType: s.mimeType,
          );
          _queue[i] = _queue[i].copyWith(
            uploadStatus: UploadStatus.uploaded,
            remoteUrl: url,
            error: null,
          );
          await _byteStore.remove(s.id);
        } catch (e) {
          final int attempts = s.attempts + 1;
          _queue[i] = _queue[i].copyWith(
            uploadStatus: UploadStatus.failed,
            attempts: attempts,
            error: e.toString(),
          );
          if (attempts < maxAttempts) {
            await Future<void>.delayed(Duration(milliseconds: 150 * attempts));
          }
        }
        _emit();
      }
    } finally {
      _processing = false;
    }
  }

  void _emit() => _controller.add(pending);

  Future<void> dispose() => _controller.close();
}
