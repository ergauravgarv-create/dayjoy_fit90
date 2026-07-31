import '../../l10n/gen/app_localizations.dart';
import '../constants/app_constants.dart';

/// Maps the [DailyTaskType] enum to localized labels (the enum itself stays
/// language-neutral).
String localizedTaskTitle(AppLocalizations l, DailyTaskType type) =>
    switch (type) {
      DailyTaskType.morningYoga => l.taskMorningYoga,
      DailyTaskType.morningNutrition => l.taskMorningNutrition,
      DailyTaskType.fitnessActivity => l.taskFitnessActivity,
      DailyTaskType.dailySteps => l.taskDailySteps,
      DailyTaskType.nightNutrition => l.taskNightNutrition,
    };

String localizedTaskSubtitle(AppLocalizations l, DailyTaskType type) =>
    switch (type) {
      DailyTaskType.morningYoga => l.taskYogaSub,
      DailyTaskType.morningNutrition => l.taskNutritionSub,
      DailyTaskType.fitnessActivity => l.taskFitnessSub,
      DailyTaskType.dailySteps => l.taskStepsSub,
      DailyTaskType.nightNutrition => l.taskNutritionSub,
    };
