// REAL IMPLEMENTATION — enable with the firebase_auth dependency and uncomment
// the branch in lib/state/repository_providers.dart. Not compiled in mock mode.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthUser? _map(User? u) =>
      u == null ? null : AuthUser(uid: u.uid, phone: u.phoneNumber ?? '');

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<void> sendOtp(
    String phoneE164, {
    required void Function(String verificationId) onCodeSent,
    void Function(String error)? onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      verificationCompleted: (PhoneAuthCredential cred) async {
        // Android instant-verification / auto-retrieval.
        await _auth.signInWithCredential(cred);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError?.call(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (String _) {},
    );
  }

  @override
  Future<AuthUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final res = await _auth.signInWithCredential(cred);
    final user = res.user!;
    // Force-refresh so a freshly-set role claim is reflected immediately.
    final token = await user.getIdTokenResult(true);
    return AuthUser(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
      role: _role(token.claims?['role']),
    );
  }

  UserRole _role(Object? claim) {
    switch (claim) {
      case 'coach':
        return UserRole.coach;
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.participant;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
