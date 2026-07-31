import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The user-selected UI locale. `null` means follow the system language.
final localeProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null; // system default

  /// Pass null to revert to the system language.
  void set(Locale? locale) => state = locale;
}

/// Languages offered in the in-app switcher.
const List<Locale> kSupportedUiLocales = [
  Locale('en'),
  Locale('hi'),
  Locale('mr'),
];
