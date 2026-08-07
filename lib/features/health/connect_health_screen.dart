import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/health_enums.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/health_providers.dart';

/// Dedicated health-connection page. Renders as "Connect Health Data"
/// (Health Connect) on Android and "Connect Apple Health" on iOS, driven by the
/// active [HealthDataService.platform].
class ConnectHealthScreen extends ConsumerStatefulWidget {
  const ConnectHealthScreen({super.key});

  @override
  ConsumerState<ConnectHealthScreen> createState() =>
      _ConnectHealthScreenState();
}

class _ConnectHealthScreenState extends ConsumerState<ConnectHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthConnectionControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthConnectionControllerProvider);
    final controller =
        ref.read(healthConnectionControllerProvider.notifier);
    final service = ref.read(healthServiceProvider);
    final bool isApple = service.platform == HealthPlatform.ios;
    final l = AppLocalizations.of(context);
    final String title =
        isApple ? l.connectAppleHealthTitle : l.connectHealthDataTitle;
    final String source = isApple ? 'Apple Health' : 'Health Connect';
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        children: [
          const SizedBox(height: AppSpacing.md),

          // Status card
          GlassCard(
            gradient: state.connected ? AppColors.brandGradient : null,
            child: Row(
              children: [
                Icon(
                  state.connected
                      ? Icons.check_circle_rounded
                      : Icons.health_and_safety_outlined,
                  size: 40,
                  color: state.connected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.connected
                            ? l.statusConnected
                            : l.statusNotConnected,
                        style: text.titleMedium?.copyWith(
                            color:
                                state.connected ? Colors.white : null),
                      ),
                      Text(
                        state.connected
                            ? l.readingStepsFrom(source)
                            : l.connectAutoTrack,
                        style: text.bodySmall?.copyWith(
                            color: state.connected
                                ? Colors.white70
                                : null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (state.connected) ...[
            _MetricRow(
                label: l.metricTodaysSteps,
                value: '${state.todaySteps} / ${AppConstants.dailyStepGoal}'),
            if (state.distanceKm != null)
              _MetricRow(
                  label: l.metricDistance,
                  value: '${state.distanceKm!.toStringAsFixed(1)} km'),
            if (state.activeCalories != null)
              _MetricRow(
                  label: l.metricActiveCalories,
                  value: '${state.activeCalories!.round()} kcal'),
            if (state.workoutMinutes != null)
              _MetricRow(
                  label: l.metricWorkout,
                  value: '${state.workoutMinutes} min'),
            if (state.sleepMinutes != null)
              _MetricRow(
                  label: 'Sleep (last night)',
                  value:
                      '${state.sleepMinutes! ~/ 60}h ${state.sleepMinutes! % 60}m'),
            _MetricRow(
              label: l.metricLastSynced,
              value: state.lastSyncAt == null
                  ? '—'
                  : DateFormat('d MMM, h:mm a').format(state.lastSyncAt!),
            ),
            _MetricRow(label: l.metricDataSource, value: source, last: true),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.syncStatus == SyncStatus.syncing
                        ? null
                        : controller.syncNow,
                    icon: state.syncStatus == SyncStatus.syncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync_rounded),
                    label: Text(l.actionSyncNow),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => service.openPermissionSettings(),
                    child: Text(l.actionManage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: controller.disconnect,
              icon: const Icon(Icons.link_off_rounded, size: 18),
              label: Text(l.actionDisconnect),
            ),
          ] else ...[
            _buildDisconnected(context, state, controller, l),
          ],

          const SizedBox(height: AppSpacing.xl),
          _Troubleshooting(source: source),
        ],
      ),
    );
  }

  Widget _buildDisconnected(
    BuildContext context,
    HealthConnectionState state,
    HealthConnectionController controller,
    AppLocalizations l,
  ) {
    final TextTheme text = Theme.of(context).textTheme;

    // Permission permanently denied → only Settings can fix it.
    if (state.permission.needsSettings) {
      return Column(
        children: [
          Text(
            l.permPermanentlyDenied,
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () =>
                ref.read(healthServiceProvider).openPermissionSettings(),
            icon: const Icon(Icons.settings_rounded),
            label: Text(l.openSettings),
          ),
          const SizedBox(height: AppSpacing.sm),
          _screenshotFallbackHint(text, l),
        ],
      );
    }

    if (state.permission == PermissionStatus.unavailable) {
      return Column(
        children: [
          Text(
            l.healthUnavailable,
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _screenshotFallbackHint(text, l),
        ],
      );
    }

    return Column(
      children: [
        Text(
          l.healthReadOnlyNote,
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: controller.connect,
          icon: const Icon(Icons.favorite_rounded),
          label: Text(l.connectGrant),
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(state.error!,
              style: text.bodySmall?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
              onPressed: controller.connect, child: Text(l.actionRetry)),
        ],
        const SizedBox(height: AppSpacing.md),
        _screenshotFallbackHint(text, l),
      ],
    );
  }

  Widget _screenshotFallbackHint(TextTheme text, AppLocalizations l) => Text(
        l.screenshotFallbackHint,
        style: text.bodySmall,
        textAlign: TextAlign.center,
      );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(
      {required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: text.bodyMedium),
              Text(value, style: text.titleSmall),
            ],
          ),
        ),
        if (!last) const Divider(height: 1),
      ],
    );
  }
}

class _Troubleshooting extends StatelessWidget {
  const _Troubleshooting({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded,
                  size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(l.troubleshooting,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.troubleshootingBody(source),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
