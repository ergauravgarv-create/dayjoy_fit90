import 'health_enums.dart';

/// A photo captured for a task, with the metadata the backend needs for
/// verification: the true submission timestamp, whether it was a live capture
/// or a gallery pick, its content hash (for duplicate detection), and size.
class PhotoSubmission {
  const PhotoSubmission({
    required this.id,
    required this.localPath,
    required this.taskKey,
    required this.captureSource,
    required this.capturedAt,
    required this.sizeBytes,
    required this.mimeType,
    this.width,
    this.height,
    this.imageHash,
    this.remoteUrl,
    this.uploadStatus = UploadStatus.queued,
    this.attempts = 0,
    this.error,
  });

  final String id;
  final String localPath;

  /// Identifies which task/day this belongs to, e.g. "morningYoga:day23".
  final String taskKey;

  final CaptureSource captureSource;

  /// The ORIGINAL submission time, captured on device and stored separately in
  /// the backend so a delayed upload cannot backdate/forward-date a submission.
  final DateTime capturedAt;

  final int sizeBytes;
  final String mimeType;
  final int? width;
  final int? height;

  /// Content hash used to detect duplicate submissions (never rely on filename).
  final String? imageHash;

  final String? remoteUrl;
  final UploadStatus uploadStatus;
  final int attempts;
  final String? error;

  bool get isLiveCapture => captureSource == CaptureSource.liveCamera;

  PhotoSubmission copyWith({
    String? imageHash,
    String? remoteUrl,
    UploadStatus? uploadStatus,
    int? attempts,
    String? error,
  }) {
    return PhotoSubmission(
      id: id,
      localPath: localPath,
      taskKey: taskKey,
      captureSource: captureSource,
      capturedAt: capturedAt,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      width: width,
      height: height,
      imageHash: imageHash ?? this.imageHash,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      attempts: attempts ?? this.attempts,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'localPath': localPath,
        'taskKey': taskKey,
        'captureSource': captureSource.name,
        'capturedAt': capturedAt.toIso8601String(),
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
        'width': width,
        'height': height,
        'imageHash': imageHash,
        'remoteUrl': remoteUrl,
        'uploadStatus': uploadStatus.name,
        'attempts': attempts,
        'error': error,
      };

  factory PhotoSubmission.fromJson(Map<String, dynamic> j) => PhotoSubmission(
        id: j['id'] as String,
        localPath: j['localPath'] as String,
        taskKey: j['taskKey'] as String,
        captureSource: CaptureSource.values.byName(j['captureSource'] as String),
        capturedAt: DateTime.parse(j['capturedAt'] as String),
        sizeBytes: (j['sizeBytes'] as num).toInt(),
        mimeType: j['mimeType'] as String,
        width: (j['width'] as num?)?.toInt(),
        height: (j['height'] as num?)?.toInt(),
        imageHash: j['imageHash'] as String?,
        remoteUrl: j['remoteUrl'] as String?,
        uploadStatus: UploadStatus.values.byName(j['uploadStatus'] as String),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        error: j['error'] as String?,
      );
}
