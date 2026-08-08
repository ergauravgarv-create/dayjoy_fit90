import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'breathing_data.dart';

/// Animated breathing guide: a circle that expands on the inhale and contracts
/// on the exhale, in time with the chosen [BreathPattern]. Pops `true` when the
/// full set of cycles is finished.
class BreathingTimerScreen extends StatefulWidget {
  const BreathingTimerScreen({super.key, required this.pattern});
  final BreathPattern pattern;

  @override
  State<BreathingTimerScreen> createState() => _BreathingTimerScreenState();
}

class _BreathingTimerScreenState extends State<BreathingTimerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale =
      AnimationController(vsync: this, lowerBound: 0.0, upperBound: 1.0)
        ..value = 0.0;

  int _phaseIndex = 0;
  int _cycle = 1;
  int _secondsLeft = 0;
  bool _paused = false;
  bool _finished = false;
  bool _soundOn = true;
  Timer? _timer;

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _chime = AudioPlayer();

  BreathPattern get _p => widget.pattern;
  BreathPhase get _phase => _p.phases[_phaseIndex];

  @override
  void initState() {
    super.initState();
    _configureTts();
    _configureChime();
    _startPhase();
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42); // calm, slow voice
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      // Best-effort — ticks/haptics still guide the breath without it.
    }
  }

  Future<void> _configureChime() async {
    try {
      await _chime.setPlayerMode(PlayerMode.lowLatency);
      await _chime.setReleaseMode(ReleaseMode.stop);
    } catch (_) {
      // Best-effort — haptics still guide the breath without it.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    _chime.dispose();
    _scale.dispose();
    super.dispose();
  }

  /// A soft chime each second so the breath has a gentle audible rhythm.
  void _tickCue() {
    if (_soundOn) {
      _chime.play(AssetSource('sounds/chime.wav'), volume: 0.5);
    }
    HapticFeedback.selectionClick();
  }

  Future<void> _speak(String text) async {
    if (!_soundOn) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  void _startPhase() {
    final phase = _phase;
    _secondsLeft = phase.seconds;
    HapticFeedback.lightImpact();
    // Speak the cue ("Breathe in" / "Hold" / "Breathe out") so the person can
    // follow the rhythm with their eyes closed.
    _speak(phase.label);
    // Animate the circle toward this phase's target over its duration. For a
    // "hold" the target equals the current value, so it simply rests.
    _scale.animateTo(
      phase.target,
      duration: Duration(seconds: phase.seconds),
      curve: Curves.easeInOut,
    );
    _tick();
    setState(() {});
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_paused) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        _advance();
      } else {
        setState(() => _secondsLeft--);
        _tickCue(); // audible tick each second
      }
    });
  }

  void _advance() {
    if (_phaseIndex < _p.phases.length - 1) {
      _phaseIndex++;
      _startPhase();
      return;
    }
    // Wrapped a full cycle.
    if (_cycle >= _p.cycles) {
      _finish();
      return;
    }
    _cycle++;
    _phaseIndex = 0;
    _startPhase();
  }

  void _finish() {
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    _speak('Well done. Take that calm with you.');
    setState(() => _finished = true);
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _scale.stop();
    } else {
      // Resume the animation toward the current phase target for the remaining
      // seconds.
      _scale.animateTo(
        _phase.target,
        duration: Duration(seconds: _secondsLeft),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _p.color;
    return Scaffold(
      appBar: AppBar(
        title: Text(_p.name),
        actions: [
          IconButton(
            tooltip: _soundOn ? 'Mute sound' : 'Unmute sound',
            icon: Icon(_soundOn
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded),
            onPressed: () {
              if (_soundOn) _tts.stop();
              setState(() => _soundOn = !_soundOn);
            },
          ),
        ],
      ),
      body: _finished
          ? _Finished(pattern: _p)
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text('Cycle $_cycle of ${_p.cycles}',
                      style: Theme.of(context).textTheme.titleMedium),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _scale,
                        builder: (context, _) {
                          final double s = 0.55 + 0.45 * _scale.value;
                          return Container(
                            width: 260 * s,
                            height: 260 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                color.withOpacity(0.55),
                                color.withOpacity(0.18),
                              ]),
                              border: Border.all(color: color, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_phase.label,
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text('$_secondsLeft',
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Text(_p.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _togglePause,
                          icon: Icon(_paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded),
                          label: Text(_paused ? 'Resume' : 'Pause'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _finish,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Finish'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({required this.pattern});
  final BreathPattern pattern;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.self_improvement_rounded,
                  color: Colors.white, size: 50),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Well done', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You completed ${pattern.cycles} cycles of ${pattern.name}. '
              'Take that calm with you.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
