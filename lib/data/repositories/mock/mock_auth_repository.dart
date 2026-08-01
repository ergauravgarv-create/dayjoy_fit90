import 'dart:async';

import '../../mock/mock_data.dart';
import '../auth_repository.dart';

/// In-memory auth for the demo build.
///
/// Any 6-digit code signs you in. The signed-in user id is derived from the
/// phone number entered, so a NEW phone number produces a NEW user with no
/// profile yet — which makes the app show the registration form (name, age,
/// height, weight, medical conditions) before Home, exactly like a real new
/// user. Using the seeded participant's number (or leaving it blank) signs you
/// straight into the existing demo profile.
class MockAuthRepository implements AuthRepository {
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  AuthUser? _current;
  String _pendingPhone = '';

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
    _pendingPhone = phoneE164;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    onCodeSent('mock-verification-id');
  }

  @override
  Future<AuthUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final String demoDigits =
        MockData.participant.mobile.replaceAll(RegExp(r'\D'), '');
    final String digits = _pendingPhone.replaceAll(RegExp(r'\D'), '');
    // Blank/partial number or the seeded number => existing demo participant.
    final bool isDemo = digits == demoDigits || digits.length < 12;

    final String uid = isDemo ? MockData.participant.id : 'u-$digits';
    final String phone =
        _pendingPhone.trim().isEmpty ? MockData.participant.mobile : _pendingPhone;

    _current = AuthUser(uid: uid, phone: phone);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}
