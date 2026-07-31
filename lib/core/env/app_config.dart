/// Selects where the app's data comes from. `mock` is fully self-contained and
/// needs no Firebase deps (default, runnable today). `firebase` routes every
/// repository to Firestore/Auth/Storage/FCM.
///
/// GOING LIVE:
///   1. Enable the firebase_* deps in pubspec.yaml.
///   2. Uncomment the Firebase branches in lib/state/repository_providers.dart
///      and the Firebase bootstrap in lib/main.dart.
///   3. Set `backend = BackendMode.firebase` below.
enum BackendMode { mock, firebase }

abstract final class AppConfig {
  /// The active backend. Flip to [BackendMode.firebase] after wiring Firebase.
  static const BackendMode backend = BackendMode.mock;

  static bool get isFirebase => backend == BackendMode.firebase;
  static bool get isMock => backend == BackendMode.mock;
}
