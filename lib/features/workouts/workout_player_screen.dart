import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'workout_data.dart';

/// Runs a [Workout] move by move with an animated countdown, beep + vibration
/// cues, and a per-move "Watch on YouTube" link. Timed moves auto-advance; rep
/// moves wait for the "Done" tap. Pops `true` when the routine is finished.
class WorkoutPlayerScreen extends StatefulWidget {
  const WorkoutPlayerScreen({super.key, required this.workout});
  final Workout workout;

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  int _index = 0;
  bool _resting = false;
  bool _paused = false;
  bool _finished = false;
  int _secondsLeft = 0;
  int _segmentTotal = 1; // for the ring progress
  Timer? _timer;

  List<Exercise> get _exercises => widget.workout.exercises;
  Exercise get _current => _exercises[_index];
  bool get _isLast => _index == _exercises.length - 1;

  @override
  void initState() {
    super.initState();
    _startExercise();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Audio / haptic cues ---------------------------------------------------
  void _beep() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  void _cueWork() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  }

  void _cueRest() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  // --- Flow ------------------------------------------------------------------
  void _startExercise() {
    _resting = false;
    _cueWork();
    if (_current.isTimed) {
      _secondsLeft = _current.seconds!;
      _segmentTotal = _current.seconds!;
      _tick();
    } else {
      _secondsLeft = 0;
      _segmentTotal = 1;
      _timer?.cancel();
    }
    setState(() {});
  }

  void _startRest(int seconds) {
    _resting = true;
    _secondsLeft = seconds;
    _segmentTotal = seconds;
    _cueRest();
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
        if (_secondsLeft <= 3) _beep();
      }
    });
  }

  void _advance() {
    _timer?.cancel();
    if (_resting) {
      _index++;
      _startExercise();
      return;
    }
    if (_isLast) {
      _finish();
      return;
    }
    final rest = _current.restSeconds;
    if (rest > 0) {
      _startRest(rest);
    } else {
      _index++;
      _startExercise();
    }
  }

  void _finish() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    setState(() => _finished = true);
  }

  void _togglePause() => setState(() => _paused = !_paused);

  void _skip() => _advance();

  Future<void> _watch(String url) async {
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the video.')),
      );
    }
  }

  Future<bool> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave workout?'),
        content: const Text(
            'Your progress in this session won\'t be saved. The task counts '
            'only when you finish the routine.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep going')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave')),
        ],
      ),
    );
    return quit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    final int total = _exercises.length;
    final double overall = _finished
        ? 1.0
        : ((_index + (_resting ? 0.5 : 0)) / total).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_finished) {
          Navigator.pop(context, true);
          return;
        }
        if (await _confirmQuit() && mounted) Navigator.pop(context, false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(w.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: overall,
              minHeight: 4,
              backgroundColor: AppColors.primary.withOpacity(0.10),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        body:
            _finished ? _buildFinished(context) : _buildActive(context, total),
      ),
    );
  }

  Widget _buildActive(BuildContext context, int total) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color color =
        _resting ? AppColors.info : widget.workout.category.color;
    final Exercise ex = _current;
    final Exercise? next =
        (_index + 1 < _exercises.length) ? _exercises[_index + 1] : null;
    final double ringValue = (ex.isTimed || _resting) && _segmentTotal > 0
        ? (1 - (_secondsLeft / _segmentTotal)).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _resting ? 'REST' : 'MOVE ${_index + 1} OF $total',
            style: text.labelLarge?.copyWith(
                color: color, fontWeight: FontWeight.w800, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 210,
                          height: 210,
                          child: CircularProgressIndicator(
                            value: (ex.isTimed || _resting) ? ringValue : null,
                            strokeWidth: 10,
                            backgroundColor: color.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                        if (ex.isTimed || _resting)
                          Text('$_secondsLeft',
                              style: text.displayLarge?.copyWith(
                                  color: color, fontWeight: FontWeight.w800))
                        else
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('×${ex.reps}',
                                  style: text.displayMedium?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w800)),
                              Text('reps', style: text.bodyMedium),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(_resting ? 'Get ready' : ex.name,
                      style: text.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_resting ? 'Next: ${next?.name ?? ''}' : ex.cue,
                      style: text.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                  if (!_resting) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      onPressed: () => _watch(ex.youtubeUrl),
                      icon: const Icon(Icons.play_circle_outline_rounded,
                          color: Color(0xFFFF0000)),
                      label: const Text('Watch on YouTube'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!_resting && next != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('Up next: ${next.name}',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ),
          Row(
            children: [
              if (ex.isTimed || _resting)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(_paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded),
                    label: Text(_paused ? 'Resume' : 'Pause'),
                  ),
                ),
              if (ex.isTimed || _resting) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _skip,
                  icon: Icon(_resting
                      ? Icons.fast_forward_rounded
                      : (ex.isTimed
                          ? Icons.skip_next_rounded
                          : Icons.check_rounded)),
                  label: Text(_resting
                      ? 'Skip rest'
                      : (ex.isTimed ? 'Skip' : 'Done')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinished(BuildContext context) {
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
              child:
                  const Icon(Icons.check_rounded, color: Colors.white, size: 52),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Workout complete!', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Great work — you finished ${widget.workout.title}. '
              'Your Fitness Activity task is done for today.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
