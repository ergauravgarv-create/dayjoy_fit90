/// Shared enums for the camera + health-sync engine. Kept in one place so the
/// services, repositories, models, and UI all speak the same vocabulary.

/// Which OS health platform a user is on.
enum HealthPlatform { android, ios, unknown }

/// The integration actually used to read health data.
enum IntegrationType { healthConnect, healthKit, googleFit, manual, none }

/// Where a health reading (or a photo) originated.
enum SourceType { phone, watch, thirdPartyApp, manual, screenshot, unknown }

/// Result of a permission request. Mirrors the union of Android + iOS states.
enum PermissionStatus {
  notDetermined,
  granted,
  partiallyGranted,
  denied,
  permanentlyDenied,
  unavailable,
}

extension PermissionStatusX on PermissionStatus {
  bool get isUsable =>
      this == PermissionStatus.granted ||
      this == PermissionStatus.partiallyGranted;

  /// Permanently denied → the only recovery is the OS Settings screen.
  bool get needsSettings => this == PermissionStatus.permanentlyDenied;
}

/// Lifecycle of a single sync attempt.
enum SyncStatus { idle, syncing, success, failed, stale }

/// How a task's completion was verified.
enum VerificationMethod { automaticHealthSync, screenshot, manualEntry }

extension VerificationMethodX on VerificationMethod {
  String get label => switch (this) {
        VerificationMethod.automaticHealthSync => 'Auto-synced',
        VerificationMethod.screenshot => 'Screenshot',
        VerificationMethod.manualEntry => 'Manual',
      };
}

/// Admin review state for a submission.
enum AdminVerificationStatus { autoVerified, pending, approved, rejected }

/// How a photo was acquired — live capture is preferred and flagged
/// differently from a gallery pick.
enum CaptureSource { liveCamera, gallery }

/// Upload lifecycle for a captured photo.
enum UploadStatus { queued, uploading, uploaded, failed }

/// Permissions the app may request at runtime.
enum AppPermission { camera, photos, notifications, healthData }
