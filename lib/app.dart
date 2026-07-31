import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';
import 'shared/widgets/demo_banner.dart';
import 'state/locale_provider.dart';

/// Root widget. Themed, Material 3, light + dark, localized (en/hi/mr), driven
/// by go_router.
class DayjoyApp extends ConsumerWidget {
  const DayjoyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? locale = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      // Localization
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Show the "Demo Data" indicator while running on sample data.
      builder: (context, child) =>
          DemoModeOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
