import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/env/app_config.dart';
import 'state/prefs_provider.dart';
import 'state/reminders_provider.dart';

// GOING LIVE: enable firebase_core and uncomment.
// import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isFirebase) {
    // Initialise Firebase using the native config files (google-services.json /
    // GoogleService-Info.plist), or `flutterfire configure` + DefaultFirebaseOptions.
    //
    // Wrapped in try/catch so a missing or misconfigured credential degrades
    // gracefully instead of crashing the app on launch.
    try {
      // await Firebase.initializeApp();
    } catch (e, s) {
      // App continues; features needing Firebase will simply be unavailable.
      debugPrint('Firebase init failed (continuing without it): $e');
      debugPrintStack(stackTrace: s);
    }
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final prefs = await SharedPreferences.getInstance();

  // Re-arm any enabled daily reminders (no-op on web; never blocks launch).
  await bootstrapReminders(prefs);

  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const DayjoyApp(),
  ));
}
