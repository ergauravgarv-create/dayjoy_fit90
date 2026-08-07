import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Canonical Surya Namaskar warm-up move, reused across routines so its cue
/// lives in one place. Follow-along videos live in the separate video library
/// (see workout_videos.dart) — the timer routines stay video-free.
const Exercise kSuryaWarmup = Exercise(
  name: 'Surya Namaskar (Sun Salutation)',
  cue: 'Warm-up: flow the 12 poses with your breath',
  seconds: 60,
);

enum WorkoutCategory { homeCardio, strength, yoga, core }

extension WorkoutCategoryX on WorkoutCategory {
  String get label => switch (this) {
        WorkoutCategory.homeCardio => 'Cardio (No Equipment)',
        WorkoutCategory.strength => 'Strength',
        WorkoutCategory.yoga => 'Yoga',
        WorkoutCategory.core => 'Core',
      };

  IconData get icon => switch (this) {
        WorkoutCategory.homeCardio => Icons.directions_run_rounded,
        WorkoutCategory.strength => Icons.fitness_center_rounded,
        WorkoutCategory.yoga => Icons.self_improvement_rounded,
        WorkoutCategory.core => Icons.accessibility_new_rounded,
      };

  Color get color => switch (this) {
        WorkoutCategory.homeCardio => AppColors.taskSteps,
        WorkoutCategory.strength => AppColors.orange,
        WorkoutCategory.yoga => AppColors.taskYoga,
        WorkoutCategory.core => AppColors.primary,
      };
}

enum WorkoutLevel { beginner, intermediate }

extension WorkoutLevelX on WorkoutLevel {
  String get label => switch (this) {
        WorkoutLevel.beginner => 'Beginner',
        WorkoutLevel.intermediate => 'Intermediate',
      };
}

/// Effort band a session is built for. Chosen automatically from the
/// participant's BMI + lifestyle, and adjustable in the UI.
enum Intensity { gentle, moderate, intense }

extension IntensityX on Intensity {
  String get label => switch (this) {
        Intensity.gentle => 'Gentle',
        Intensity.moderate => 'Moderate',
        Intensity.intense => 'Intense',
      };

  String get blurb => switch (this) {
        Intensity.gentle => 'Low-impact, joint-friendly moves',
        Intensity.moderate => 'A balanced fat-burn circuit',
        Intensity.intense => 'High-energy, athletic circuit',
      };

  IconData get icon => switch (this) {
        Intensity.gentle => Icons.spa_rounded,
        Intensity.moderate => Icons.local_fire_department_rounded,
        Intensity.intense => Icons.bolt_rounded,
      };

  Color get color => switch (this) {
        Intensity.gentle => AppColors.info,
        Intensity.moderate => AppColors.orange,
        Intensity.intense => AppColors.error,
      };
}

/// Builds a YouTube URL for a move: a specific [explicit] link if provided,
/// otherwise a search for the exercise so the user always lands on a free
/// how-to video (no fabricated video ids).
String youtubeUrlFor(String exerciseName, {String? explicit}) {
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final q = Uri.encodeQueryComponent('$exerciseName exercise proper form');
  return 'https://www.youtube.com/results?search_query=$q';
}

/// A single move. Either time-based ([seconds]) or rep-based ([reps]).
/// [asset] is an optional illustration/GIF path (drop files into
/// assets/workouts/ later and they render automatically). [videoUrl] pins a
/// specific reference video; otherwise a YouTube search is used.
class Exercise {
  const Exercise({
    required this.name,
    required this.cue,
    this.seconds,
    this.reps,
    this.restSeconds = 15,
    this.asset,
    this.videoUrl,
  });

  final String name;
  final String cue;
  final int? seconds;
  final int? reps;
  final int restSeconds;
  final String? asset;
  final String? videoUrl;

  bool get isTimed => seconds != null;

  int get workSeconds => seconds ?? ((reps ?? 10) * 3);

  String get youtubeUrl => youtubeUrlFor(name, explicit: videoUrl);

  Exercise copyWith({int? seconds, int? reps, int? restSeconds}) => Exercise(
        name: name,
        cue: cue,
        seconds: seconds ?? this.seconds,
        reps: reps ?? this.reps,
        restSeconds: restSeconds ?? this.restSeconds,
        asset: asset,
        videoUrl: videoUrl,
      );
}

class Workout {
  const Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.focus,
    required this.exercises,
    this.intensity,
    this.referenceVideoUrl,
    this.generated = false,
  });

  final String id;
  final String title;
  final WorkoutCategory category;
  final WorkoutLevel level;
  final String focus;
  final List<Exercise> exercises;
  final Intensity? intensity;
  final String? referenceVideoUrl;
  final bool generated;

  int get exerciseCount => exercises.length;

  int get estMinutes {
    int secs = 0;
    for (int i = 0; i < exercises.length; i++) {
      secs += exercises[i].workSeconds;
      if (i < exercises.length - 1) secs += exercises[i].restSeconds;
    }
    final m = (secs / 60).ceil();
    return m < 1 ? 1 : m;
  }
}

// ===========================================================================
// Personalisation: pick an intensity from the participant's BMI + lifestyle.
// ===========================================================================

/// Recommended intensity from WHO BMI category + self-reported activity level.
/// Errs on the safe side: heavier or sedentary → gentler start.
Intensity recommendedIntensity({
  required String bmiCategory,
  String? activityLevel,
}) {
  final sedentary =
      activityLevel == 'Sedentary' || activityLevel == 'Light';
  final athletic =
      activityLevel == 'Active' || activityLevel == 'Very active';

  if (bmiCategory == 'Obese' || sedentary) return Intensity.gentle;
  if (bmiCategory == 'Overweight') return Intensity.moderate;
  if ((bmiCategory == 'Normal' || bmiCategory == 'Underweight') && athletic) {
    return Intensity.intense;
  }
  return Intensity.moderate;
}

/// A short "why this fits you" line for the recommendation card.
String intensityReason({
  required String bmiCategory,
  String? activityLevel,
}) {
  final level = (activityLevel == null || activityLevel.isEmpty)
      ? 'your lifestyle'
      : '$activityLevel lifestyle';
  return 'Matched to your $bmiCategory BMI and $level.';
}

// ===========================================================================
// Move pools for the generated circuit (30s work / 30s rest sets).
// ===========================================================================

const List<({String name, String cue})> _cooldowns = [
  (name: 'Standing forward fold', cue: 'Soft knees, hang heavy'),
  (name: 'Quad & hamstring stretch', cue: 'Ease into it, breathe'),
  (name: 'Deep breathing', cue: 'In through nose, long exhale'),
];

const Map<Intensity, List<({String name, String cue})>> _poolByIntensity = {
  Intensity.gentle: [
    (name: 'Step touch', cue: 'Side to side, stay light'),
    (name: 'Standing knee lifts', cue: 'Alternate knees up'),
    (name: 'Sit-to-stand', cue: 'Use a chair if needed'),
    (name: 'Wall push-ups', cue: 'Chest toward the wall'),
    (name: 'Standing side crunch', cue: 'Elbow to hip'),
    (name: 'Toe taps', cue: 'Light and steady'),
    (name: 'Glute bridge', cue: 'Squeeze at the top'),
    (name: 'Calf raises', cue: 'Up on toes, hold 1s'),
    (name: 'Standing march twist', cue: 'Rotate through the waist'),
    (name: 'Heel taps (seated)', cue: 'Controlled, brace core'),
  ],
  Intensity.moderate: [
    (name: 'Jumping jacks', cue: 'Full range, steady pace'),
    (name: 'Bodyweight squats', cue: 'Knees track toes'),
    (name: 'Knee push-ups', cue: 'Body in a straight line'),
    (name: 'Reverse lunges', cue: 'Step back, knee down'),
    (name: 'Mountain climbers', cue: 'Hips low, quick feet'),
    (name: 'High knees', cue: 'Drive knees up'),
    (name: 'Plank hold', cue: 'One line head to heel'),
    (name: 'Glute bridge march', cue: 'Hips up, march slow'),
    (name: 'Bicycle crunches', cue: 'Elbow to opposite knee'),
    (name: 'Squat to reach', cue: 'Sit back, reach tall'),
  ],
  Intensity.intense: [
    (name: 'Burpees', cue: 'Chest down, jump up'),
    (name: 'Jump squats', cue: 'Explode up, land soft'),
    (name: 'Push-ups', cue: 'Elbows ~45°, tight core'),
    (name: 'Skater hops', cue: 'Side to side, land soft'),
    (name: 'Mountain climbers', cue: 'Fast feet, hips low'),
    (name: 'Jumping lunges', cue: 'Switch legs mid-air'),
    (name: 'Plank shoulder taps', cue: 'Hips still, tap slow'),
    (name: 'Tuck jumps', cue: 'Knees to chest'),
    (name: 'Russian twists', cue: 'Rotate through the waist'),
    (name: 'Squat + knee drive', cue: 'Squat, then drive knee'),
  ],
};

/// Builds a personalised circuit: a warm-up, a main block of 30s-work /
/// 30s-rest sets cycling the intensity pool, and a cool-down. [minutes] is one
/// of 30 / 45 / 60. Each work+rest slot is ~60s, so the count scales with time.
Workout buildSession({required Intensity intensity, required int minutes}) {
  const int workSecs = 30;
  const int restSecs = 30;
  final pool = _poolByIntensity[intensity]!;

  // ~60s per slot (30 work + 30 rest). Reserve one warm-up and one cool-down.
  final int slots = minutes; // minutes * 60 / 60
  final int mainCount = (slots - 2) < 1 ? 1 : (slots - 2);

  final moves = <Exercise>[];

  // Warm-up: Surya Namaskar (Sun Salutation) — a full 60s flow to open up,
  // with its own reference video.
  moves.add(kSuryaWarmup.copyWith(restSeconds: restSecs));

  // Main circuit — cycle the pool so longer sessions repeat as rounds.
  for (int i = 0; i < mainCount; i++) {
    final m = pool[i % pool.length];
    moves.add(Exercise(
        name: m.name, cue: m.cue, seconds: workSecs, restSeconds: restSecs));
  }

  // Cool-down (no trailing rest).
  final c = _cooldowns[0];
  moves.add(
      Exercise(name: c.name, cue: c.cue, seconds: workSecs, restSeconds: 0));

  return Workout(
    id: 'session_${intensity.name}_$minutes',
    title: '$minutes-min ${intensity.label} Session',
    category: WorkoutCategory.homeCardio,
    level: intensity == Intensity.intense
        ? WorkoutLevel.intermediate
        : WorkoutLevel.beginner,
    focus: '${intensity.blurb} · 30s work / 30s rest',
    exercises: moves,
    intensity: intensity,
    generated: true,
  );
}

// ===========================================================================
// Curated browse library (kept from the first version).
// ===========================================================================

const List<Workout> kWorkouts = [
  Workout(
    id: 'cardio_starter',
    title: 'Fat-Burn Starter',
    category: WorkoutCategory.homeCardio,
    level: WorkoutLevel.beginner,
    focus: 'Fat burn · low impact',
    exercises: [
      Exercise(name: 'March in place', cue: 'Lift knees, pump arms', seconds: 40),
      Exercise(name: 'Step touch', cue: 'Side to side, stay light', seconds: 40),
      Exercise(name: 'Standing knee lifts', cue: 'Alternate knees to chest', reps: 20),
      Exercise(name: 'Toe taps', cue: 'Quick taps forward', seconds: 30),
      Exercise(name: 'Half jacks', cue: 'Arms up, tap foot out', seconds: 30),
      Exercise(name: 'Cool-down march', cue: 'Slow it down, breathe', seconds: 30, restSeconds: 0),
    ],
  ),
  Workout(
    id: 'cardio_hiit',
    title: 'HIIT Sweat',
    category: WorkoutCategory.homeCardio,
    level: WorkoutLevel.intermediate,
    focus: 'High intensity · fat burn',
    exercises: [
      Exercise(name: 'Jumping jacks', cue: 'Full range, steady pace', seconds: 45),
      Exercise(name: 'High knees', cue: 'Drive knees up fast', seconds: 40),
      Exercise(name: 'Squat to reach', cue: 'Sit back, reach tall', reps: 15),
      Exercise(name: 'Mountain climbers', cue: 'Hips low, quick feet', seconds: 40),
      Exercise(name: 'Skater hops', cue: 'Side to side, land soft', seconds: 40),
      Exercise(name: 'Burpees', cue: 'Chest down, jump up', reps: 10),
      Exercise(name: 'Recovery march', cue: 'Breathe, shake it out', seconds: 30, restSeconds: 0),
    ],
  ),
  // ---- More no-equipment cardio (each opens with Surya Namaskar) ---------
  Workout(
    id: 'cardio_low_impact',
    title: 'Low-Impact Cardio',
    category: WorkoutCategory.homeCardio,
    level: WorkoutLevel.beginner,
    focus: 'No jumping · joint-friendly · no equipment',
    exercises: [
      kSuryaWarmup,
      Exercise(name: 'March in place', cue: 'Lift knees, pump arms', seconds: 40),
      Exercise(name: 'Step touch', cue: 'Side to side, stay light', seconds: 40),
      Exercise(name: 'Standing knee lifts', cue: 'Alternate knees to chest', seconds: 40),
      Exercise(name: 'Side leg taps', cue: 'Tap out, squeeze back in', seconds: 30),
      Exercise(name: 'Boxer shuffle', cue: 'Light bounce, guard up', seconds: 40),
      Exercise(name: 'Cool-down march', cue: 'Slow it down, breathe', seconds: 40, restSeconds: 0),
    ],
  ),
  Workout(
    id: 'cardio_kickboxing',
    title: 'Cardio Kickboxing',
    category: WorkoutCategory.homeCardio,
    level: WorkoutLevel.intermediate,
    focus: 'Punch & kick combos · no equipment',
    exercises: [
      kSuryaWarmup,
      Exercise(name: 'Jab – cross', cue: 'Rotate hips into each punch', seconds: 40),
      Exercise(name: 'Front kicks', cue: 'Alternate legs, snap back', seconds: 40),
      Exercise(name: 'Knee strikes', cue: 'Pull down, drive knee up', seconds: 40),
      Exercise(name: 'Squat + double punch', cue: 'Sit, stand, punch out', seconds: 40),
      Exercise(name: 'High knees', cue: 'Fast feet, drive knees', seconds: 30),
      Exercise(name: 'Cool-down shuffle', cue: 'Ease off, shake it out', seconds: 40, restSeconds: 0),
    ],
  ),
  Workout(
    id: 'cardio_dance',
    title: 'Dance Cardio Burn',
    category: WorkoutCategory.homeCardio,
    level: WorkoutLevel.beginner,
    focus: 'Fun, rhythmic moves · no equipment',
    exercises: [
      kSuryaWarmup,
      Exercise(name: 'Grapevine', cue: 'Step-behind side to side', seconds: 40),
      Exercise(name: 'Step touch with claps', cue: 'Keep it bouncy', seconds: 40),
      Exercise(name: 'Hip twists', cue: 'Rotate through the waist', seconds: 30),
      Exercise(name: 'Side lunges', cue: 'Push hips back, alternate', seconds: 40),
      Exercise(name: 'Marching with arms', cue: 'Big arm swings', seconds: 40),
      Exercise(name: 'Cool-down sway', cue: 'Slow, relax shoulders', seconds: 40, restSeconds: 0),
    ],
  ),
  Workout(
    id: 'cardio_tabata',
    title: 'Tabata Cardio Blast',
    category: WorkoutCategory.homeCardio,
    level: WorkoutLevel.intermediate,
    focus: 'High-intensity intervals · no equipment',
    exercises: [
      kSuryaWarmup,
      Exercise(name: 'Jumping jacks', cue: 'Full range, steady pace', seconds: 40),
      Exercise(name: 'Mountain climbers', cue: 'Hips low, quick feet', seconds: 40),
      Exercise(name: 'Burpees', cue: 'Chest down, jump up', seconds: 30),
      Exercise(name: 'High knees', cue: 'Drive knees up fast', seconds: 40),
      Exercise(name: 'Skater hops', cue: 'Side to side, land soft', seconds: 40),
      Exercise(name: 'Cool-down march', cue: 'Breathe, shake it out', seconds: 40, restSeconds: 0),
    ],
  ),

  Workout(
    id: 'strength_basics',
    title: 'Full-Body Basics',
    category: WorkoutCategory.strength,
    level: WorkoutLevel.beginner,
    focus: 'Tone · full body',
    exercises: [
      Exercise(name: 'Bodyweight squats', cue: 'Knees track toes', reps: 12),
      Exercise(name: 'Wall / knee push-ups', cue: 'Chest to wall/floor', reps: 10),
      Exercise(name: 'Glute bridge', cue: 'Squeeze at the top', reps: 15),
      Exercise(name: 'Standing calf raises', cue: 'Up on toes, hold 1s', reps: 15),
      Exercise(name: 'Superman hold', cue: 'Lift chest & legs', seconds: 25),
    ],
  ),
  Workout(
    id: 'strength_build',
    title: 'Strength Builder',
    category: WorkoutCategory.strength,
    level: WorkoutLevel.intermediate,
    focus: 'Build · full body',
    exercises: [
      Exercise(name: 'Jump squats', cue: 'Explode up, land soft', reps: 15),
      Exercise(name: 'Push-ups', cue: 'Elbows ~45°, body straight', reps: 12),
      Exercise(name: 'Reverse lunges', cue: 'Step back, knee down', reps: 20),
      Exercise(name: 'Pike push-ups', cue: 'Hips high, head to floor', reps: 10),
      Exercise(name: 'Single-leg glute bridge', cue: 'Drive through heel', reps: 20),
      Exercise(name: 'Wall sit', cue: 'Thighs parallel, hold', seconds: 45, restSeconds: 0),
    ],
  ),
  Workout(
    id: 'yoga_morning',
    title: 'Morning Flow',
    category: WorkoutCategory.yoga,
    level: WorkoutLevel.beginner,
    focus: 'Mobility · calm',
    exercises: [
      Exercise(name: 'Cat–cow', cue: 'Move with the breath', seconds: 40),
      Exercise(name: 'Downward dog', cue: 'Long spine, heels down', seconds: 40),
      Exercise(name: 'Low lunge (right)', cue: 'Sink hips, open chest', seconds: 30),
      Exercise(name: 'Low lunge (left)', cue: 'Sink hips, open chest', seconds: 30),
      Exercise(name: 'Forward fold', cue: 'Soft knees, hang heavy', seconds: 30),
      Exercise(name: 'Child\'s pose', cue: 'Rest, breathe deep', seconds: 40, restSeconds: 0),
    ],
  ),
  Workout(
    id: 'yoga_power',
    title: 'Power Yoga',
    category: WorkoutCategory.yoga,
    level: WorkoutLevel.intermediate,
    focus: 'Strength · balance',
    exercises: [
      Exercise(name: 'Sun salutation flow', cue: 'Link breath to movement', seconds: 60),
      Exercise(name: 'Warrior II (right)', cue: 'Bend front knee, gaze out', seconds: 40),
      Exercise(name: 'Warrior II (left)', cue: 'Bend front knee, gaze out', seconds: 40),
      Exercise(name: 'Chair pose', cue: 'Sit back, arms up', seconds: 40),
      Exercise(name: 'Plank hold', cue: 'One line head to heel', seconds: 40),
      Exercise(name: 'Tree pose (each side)', cue: 'Root down, breathe', seconds: 40, restSeconds: 0),
    ],
  ),
  Workout(
    id: 'core_starter',
    title: 'Core Kickstart',
    category: WorkoutCategory.core,
    level: WorkoutLevel.beginner,
    focus: 'Abs · stability',
    exercises: [
      Exercise(name: 'Dead bug', cue: 'Slow, low back flat', reps: 16),
      Exercise(name: 'Knee plank', cue: 'Brace, don\'t sag', seconds: 30),
      Exercise(name: 'Seated knee tucks', cue: 'Lean back, pull in', reps: 15),
      Exercise(name: 'Side plank (right)', cue: 'Stack hips, lift', seconds: 20),
      Exercise(name: 'Side plank (left)', cue: 'Stack hips, lift', seconds: 20),
      Exercise(name: 'Crunches', cue: 'Chin off chest, curl up', reps: 20, restSeconds: 0),
    ],
  ),
  Workout(
    id: 'core_burner',
    title: 'Core Burner',
    category: WorkoutCategory.core,
    level: WorkoutLevel.intermediate,
    focus: 'Abs · endurance',
    exercises: [
      Exercise(name: 'Full plank', cue: 'Squeeze glutes & abs', seconds: 45),
      Exercise(name: 'Bicycle crunches', cue: 'Elbow to opposite knee', reps: 24),
      Exercise(name: 'Leg raises', cue: 'Lower slow, back flat', reps: 15),
      Exercise(name: 'Russian twists', cue: 'Rotate through the waist', reps: 24),
      Exercise(name: 'Plank shoulder taps', cue: 'Hips still, tap slow', seconds: 40),
      Exercise(name: 'Hollow hold', cue: 'Low back pressed down', seconds: 30, restSeconds: 0),
    ],
  ),
];

List<Workout> workoutsIn(WorkoutCategory c) =>
    kWorkouts.where((w) => w.category == c).toList();
