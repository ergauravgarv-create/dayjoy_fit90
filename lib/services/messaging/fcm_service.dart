/// Push messaging behind one interface. Mock returns no token (nothing to
/// register); the Firebase implementation wraps FirebaseMessaging.
abstract interface class FcmService {
  Future<void> requestPermission();

  /// The device FCM token, or null when unavailable (mock / permission denied).
  Future<String?> getToken();

  /// Foreground messages, as raw data maps.
  Stream<Map<String, dynamic>> onForegroundMessage();
}

/// Runnable no-op implementation.
class MockFcmService implements FcmService {
  @override
  Future<void> requestPermission() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<Map<String, dynamic>> onForegroundMessage() =>
      Stream<Map<String, dynamic>>.empty();
}
