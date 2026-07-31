import 'dart:async';

import '../../mock/mock_data.dart';
import '../auth_repository.dart';

/// In-memory auth for the demo build. Any 6-digit code signs you in as the
/// seeded participant.
class MockAuthRepository implements AuthRepository {
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  @override
  AuthUser? get currentUser => _current;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> sendOtp(
    String phoneE164, {
    required void Function(String verificationId) onCodeSent,
    void Function(String error)? onError,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    onCodeSent('mock-verification-id');
  }

  @override
  Future<AuthUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _current = AuthUser(uid: MockData.participant.id, phone: MockData.participant.mobile);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}
