import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';

/// Bottom-navigation shell that hosts the five main tabs via an IndexedStack,
/// preserving each tab's state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_rounded),
            selectedIcon: const Icon(Icons.fact_check_rounded),
            label: l.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: l.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard_rounded),
            label: l.navRanks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l.navProfile,
          ),
        ],
      ),
    );
  }
}
