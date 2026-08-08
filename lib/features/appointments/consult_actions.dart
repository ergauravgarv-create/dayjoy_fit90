import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/appointment.dart';
import '../../shared/widgets/app_snack.dart';

/// Opens the consultation call inside the app (a private, per-appointment room).
/// Uses the in-app browser view so the call happens without leaving Dayjoy;
/// the browser view has camera & microphone access for video/voice.
Future<void> joinConsultation(BuildContext context, Appointment a) async {
  final url = a.meetingUrl;
  if (url == null) {
    showAppSnack(context, 'The call link isn\'t ready yet.',
        type: AppSnackType.info);
    return;
  }
  try {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!ok && context.mounted) {
      showAppSnack(context, 'Could not open the call on this device.',
          type: AppSnackType.error);
    }
  } catch (_) {
    if (context.mounted) {
      showAppSnack(context, 'Could not open the call on this device.',
          type: AppSnackType.error);
    }
  }
}

/// Whether the "Join" action should be available. The private room is open once
/// the provider has confirmed the booking, so either side can enter and the
/// other joins when ready.
bool canJoinNow(Appointment a) =>
    a.status == AppointmentStatus.confirmed && a.meetingUrl != null;
