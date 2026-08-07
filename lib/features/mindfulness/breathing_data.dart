import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// One phase of a breathing cycle. [target] is the breathing-circle scale to
/// animate toward (1.0 = fully expanded / lungs full, 0.0 = contracted).
class BreathPhase {
  const BreathPhase(this.label, this.seconds, this.target);
  final String label;
  final int seconds;
  final double target;
}

class BreathPattern {
  const BreathPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.phases,
    required this.cycles,
    required this.color,
  });

  final String id;
  final String name;
  final String description;
  final List<BreathPhase> phases;
  final int cycles;
  final Color color;

  int get cycleSeconds =>
      phases.fold(0, (sum, p) => sum + p.seconds);

  int get totalSeconds => cycleSeconds * cycles;
}

const List<BreathPattern> kBreathPatterns = [
  BreathPattern(
    id: 'box',
    name: 'Box Breathing',
    description: '4-4-4-4 · calm & focus',
    color: AppColors.info,
    cycles: 6,
    phases: [
      BreathPhase('Breathe in', 4, 1.0),
      BreathPhase('Hold', 4, 1.0),
      BreathPhase('Breathe out', 4, 0.0),
      BreathPhase('Hold', 4, 0.0),
    ],
  ),
  BreathPattern(
    id: 'relax478',
    name: '4-7-8 Relax',
    description: 'Wind down · sleep aid',
    color: AppColors.taskYoga,
    cycles: 5,
    phases: [
      BreathPhase('Breathe in', 4, 1.0),
      BreathPhase('Hold', 7, 1.0),
      BreathPhase('Breathe out', 8, 0.0),
    ],
  ),
  BreathPattern(
    id: 'calm46',
    name: 'Calm 4-6',
    description: 'Longer exhale · ease stress',
    color: AppColors.primary,
    cycles: 8,
    phases: [
      BreathPhase('Breathe in', 4, 1.0),
      BreathPhase('Breathe out', 6, 0.0),
    ],
  ),
];
