import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/task_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/health_enums.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../data/models/photo_submission.dart';
import '../../services/camera/camera_service.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/health_providers.dart';

/// Session-lived set of content hashes already submitted — powers duplicate
/// detection in the demo. In production this lives in the backend.
final submittedHashesProvider = Provider<Set<String>>((ref) => <String>{});

/// Whether the admin allows gallery uploads (live capture is preferred).
final galleryUploadAllowedProvider = Provider<bool>((ref) => true);

enum _Stage { idle, preview, uploading, error }

/// Camera capture → preview → (retake / use) → compress → hash/dup-check →
/// upload with progress → complete. Pops `true` only after a confirmed upload.
class ActivitySubmissionScreen extends ConsumerStatefulWidget {
  const ActivitySubmissionScreen({
    super.key,
    required this.taskType,
    required this.challengeDay,
  });

  final DailyTaskType taskType;
  final int challengeDay;

  @override
  ConsumerState<ActivitySubmissionScreen> createState() =>
      _ActivitySubmissionScreenState();
}

class _ActivitySubmissionScreenState
    extends ConsumerState<ActivitySubmissionScreen> {
  _Stage _stage = _Stage.idle;
  CaptureResult? _capture;
  double _progress = 0;
  String? _message;

  String get _taskKey => '${widget.taskType.name}:day${widget.challengeDay}';

  Future<void> _openCamera({bool gallery = false}) async {
    final CameraService cam = ref.read(cameraServiceProvider);
    // Permission is requested here in production via permissionServiceProvider.
    await ref
        .read(permissionServiceProvider)
        .request(gallery ? AppPermission.photos : AppPermission.camera);

    final CaptureResult? result =
        gallery ? await cam.pickFromGallery() : await cam.capturePhoto();
    if (!mounted) return;
    if (result == null) return; // user backed out — stay on idle
    setState(() {
      _capture = result;
      _stage = _Stage.preview;
    });
  }

  void _retake() => setState(() {
        _capture = null;
        _stage = _Stage.idle;
      });

  Future<void> _usePhoto() async {
    final CaptureResult capture = _capture!;
    setState(() {
      _stage = _Stage.uploading;
      _progress = 0;
      _message = null;
    });

    // 1) Compress + strip EXIF
    final Uint8List compressed = await ref
        .read(imageCompressionProvider)
        .compress(capture.bytes);

    // 2) Content hash + duplicate check
    final dup = ref.read(duplicateDetectionProvider);
    final String hash = dup.computeHash(compressed);
    final Set<String> known = ref.read(submittedHashesProvider);
    if (dup.isExactDuplicate(hash, known)) {
      setState(() {
        _stage = _Stage.error;
        _message = AppLocalizations.of(context).duplicatePhotoMsg;
      });
      return;
    }

    // 3) Build the submission record with the ORIGINAL capture timestamp
    final PhotoSubmission submission = PhotoSubmission(
      id: '${_taskKey}_${capture.capturedAt.millisecondsSinceEpoch}',
      localPath: 'memory://$hash',
      taskKey: _taskKey,
      captureSource: capture.source,
      capturedAt: capture.capturedAt,
      sizeBytes: compressed.lengthInBytes,
      mimeType: capture.mimeType,
      width: capture.width,
      height: capture.height,
      imageHash: hash,
    );

    // 4) Upload with progress. On failure, hand to the offline queue so it
    //    retries when connectivity returns — the task stays incomplete until
    //    the backend confirms.
    try {
      final String url = await ref.read(imageUploadServiceProvider).upload(
            compressed,
            storageKey: '${submission.taskKey}/${submission.id}',
            mimeType: submission.mimeType,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      known.add(hash);
      if (!mounted) return;
      Navigator.of(context).pop(SubmissionOutcome(
        submission: submission.copyWith(
            remoteUrl: url, uploadStatus: UploadStatus.uploaded),
      ));
    } catch (e) {
      await ref.read(offlineQueueProvider).enqueue(submission, compressed);
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _message = AppLocalizations.of(context).uploadFailedOffline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool galleryAllowed = ref.watch(galleryUploadAllowedProvider);

    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizedTaskTitle(l, widget.taskType))),
      body: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(localizedTaskSubtitle(l, widget.taskType),
                style: text.bodyMedium),
            const SizedBox(height: AppSpacing.lg),

            Expanded(child: _buildStageBody(text, l)),

            const SizedBox(height: AppSpacing.md),
            ..._buildActions(galleryAllowed, l),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildStageBody(TextTheme text, AppLocalizations l) {
    switch (_stage) {
      case _Stage.idle:
        return _PhotoDropTarget(
          icon: Icons.photo_camera_rounded,
          title: l.captureProofTitle,
          body: l.captureProofBody,
        );
      case _Stage.preview:
        return _PreviewCard(capture: _capture!);
      case _Stage.uploading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress == 0 ? null : _progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                    Text('${(_progress * 100).round()}%',
                        style: text.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l.uploadingSecurely, style: text.bodyMedium),
            ],
          ),
        );
      case _Stage.error:
        return _PhotoDropTarget(
          icon: Icons.error_outline_rounded,
          color: AppColors.error,
          title: l.somethingWrong,
          body: _message ?? l.pleaseTryAgain,
        );
    }
  }

  List<Widget> _buildActions(bool galleryAllowed, AppLocalizations l) {
    switch (_stage) {
      case _Stage.idle:
      case _Stage.error:
        return [
          FilledButton.icon(
            onPressed: () => _openCamera(),
            icon: const Icon(Icons.photo_camera_rounded),
            label: Text(l.actionOpenCamera),
          ),
          if (galleryAllowed) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _openCamera(gallery: true),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l.actionChooseGallery),
            ),
          ],
        ];
      case _Stage.preview:
        return [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retake,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l.actionRetake),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _usePhoto,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l.actionUsePhoto),
                ),
              ),
            ],
          ),
        ];
      case _Stage.uploading:
        return const [SizedBox.shrink()];
    }
  }
}

/// The outcome returned to the checklist when a submission completes.
class SubmissionOutcome {
  const SubmissionOutcome({required this.submission});
  final PhotoSubmission submission;
}

class _PhotoDropTarget extends StatelessWidget {
  const _PhotoDropTarget({
    required this.icon,
    required this.title,
    required this.body,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: text.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.capture});
  final CaptureResult capture;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final String time = DateFormat('d MMM, h:mm a').format(capture.capturedAt);
    final String size = '${(capture.sizeBytes / 1024).toStringAsFixed(0)} KB';

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.secondary.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            // In production: Image.memory(capture.bytes, fit: BoxFit.cover).
            // The mock produces synthetic bytes, so we show a stylised preview.
            child: const Center(
              child: Icon(Icons.image_rounded,
                  size: 72, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _MetaChip(
              icon: capture.source == CaptureSource.liveCamera
                  ? Icons.verified_rounded
                  : Icons.collections_rounded,
              label: capture.source == CaptureSource.liveCamera
                  ? l.liveCapture
                  : l.galleryLabel,
              color: capture.source == CaptureSource.liveCamera
                  ? AppColors.success
                  : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.sm),
            _MetaChip(icon: Icons.schedule_rounded, label: time),
            const SizedBox(width: AppSpacing.sm),
            _MetaChip(icon: Icons.sd_storage_rounded, label: size),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l.photoTimestampNote,
            style: text.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(
      {required this.icon, required this.label, this.color = AppColors.textSecondary});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
