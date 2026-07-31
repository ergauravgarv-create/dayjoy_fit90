// REAL IMPLEMENTATION — enable with firebase_messaging. Not compiled in mock
// mode.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:firebase_messaging/firebase_messaging.dart';

import 'fcm_service.dart';

class FirebaseFcmService implements FcmService {
  final FirebaseMessaging _m = FirebaseMessaging.instance;

  @override
  Future<void> requestPermission() async {
    await _m.requestPermission();
  }

  @override
  Future<String?> getToken() => _m.getToken();

  @override
  Stream<Map<String, dynamic>> onForegroundMessage() =>
      FirebaseMessaging.onMessage.map((m) => m.data);
}
