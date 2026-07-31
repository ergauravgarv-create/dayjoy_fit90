import '../../core/constants/app_constants.dart';

/// Authenticated user (minimal projection of the auth provider's user).
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.phone,
    this.role = UserRole.participant,
  });
  final String uid;
  final String phone;

  /// Role from the Firebase custom claim (participant unless staff/admin).
  final UserRole role;
}

/// Phone-OTP authentication behind one interface so the UI is identical for the
/// mock flow and Firebase Auth. Implemented by `MockAuthRepository` (default)
/// and `FirebaseAuthRepository` (ready-to-enable).
abstract interface class AuthRepository {
  /// Emits the current [AuthUser] (or null when signed out) on every change.
  Stream<AuthUser?> authStateChanges();

  /// Best-effort synchronous current user.
  AuthUser? get currentUser;

  /// Start phone verification. Calls [onCodeSent] with a verification id once
  /// the SMS is dispatched, or [onError] on failure.
  Future<void> sendOtp(
    String phoneE164, {
    required void Function(String verificationId) onCodeSent,
    void Function(String error)? onError,
  });

  /// Complete sign-in with the SMS code. Returns the signed-in user.
  Future<AuthUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();
}
