import 'dart:typed_data';

import 'package:dayjoy_fit90/data/models/daily_challenge_snapshot.dart';
import 'package:dayjoy_fit90/data/models/health_enums.dart';
import 'package:dayjoy_fit90/data/models/photo_submission.dart';
import 'package:dayjoy_fit90/services/health/mock_health_data_service.dart';
import 'package:dayjoy_fit90/services/health/step_aggregation_service.dart';
import 'package:dayjoy_fit90/services/image/duplicate_image_detection_service.dart';
import 'package:dayjoy_fit90/services/upload/image_upload_service.dart';
import 'package:dayjoy_fit90/services/upload/offline_upload_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepAggregationService', () {
    const agg = StepAggregationService();

    test('prefers the platform aggregated total', () {
      expect(
        agg.resolveTodaySteps(aggregatedTotal: 9200, perSource: {'phone': 5000}),
        9200,
      );
    });

    test('de-dupes mirrored phone + watch readings', () {
      // Phone 8000, watch 8100 (~1.25% apart) → counted once as the larger.
      expect(
        agg.resolveTodaySteps(perSource: {'phone': 8000, 'watch': 8100}),
        8100,
      );
    });

    test('sums genuinely distinct sources', () {
      expect(
        agg.resolveTodaySteps(perSource: {'phone': 3000, 'treadmill': 6000}),
        9000,
      );
    });

    test('never lowers a stored value on a delayed sync', () {
      expect(agg.reconcile(stored: 10200, incoming: 400), 10200);
      expect(agg.reconcile(stored: 400, incoming: 10200), 10200);
    });

    test('local date key is stable within a day', () {
      final a = DateTime(2026, 7, 31, 0, 1);
      final b = DateTime(2026, 7, 31, 23, 59);
      expect(agg.isSameLocalDay(a, b), isTrue);
      expect(agg.localDateKey(a), '2026-07-31');
    });

    test('goal + progress', () {
      expect(agg.goalReached(9999, 10000), isFalse);
      expect(agg.goalReached(10000, 10000), isTrue);
      expect(agg.progress(5000, 10000), closeTo(0.5, 0.001));
    });
  });

  group('DuplicateImageDetection', () {
    const svc = ContentHashDuplicateService();

    test('identical bytes hash equal; different bytes differ', () {
      final a = Uint8List.fromList([1, 2, 3, 4, 5]);
      final b = Uint8List.fromList([1, 2, 3, 4, 5]);
      final c = Uint8List.fromList([9, 9, 9]);
      expect(svc.computeHash(a), svc.computeHash(b));
      expect(svc.computeHash(a) == svc.computeHash(c), isFalse);
    });

    test('flags a known duplicate', () {
      final bytes = Uint8List.fromList([7, 7, 7, 7]);
      final hash = svc.computeHash(bytes);
      expect(svc.isExactDuplicate(hash, {hash}), isTrue);
      expect(svc.isExactDuplicate('deadbeef', {hash}), isFalse);
    });
  });

  group('OfflineUploadQueue', () {
    PhotoSubmission sub(String id) => PhotoSubmission(
          id: id,
          localPath: 'mem://$id',
          taskKey: 'morningYoga:day1',
          captureSource: CaptureSource.liveCamera,
          capturedAt: DateTime(2026, 7, 31, 8),
          sizeBytes: 4,
          mimeType: 'image/jpeg',
        );

    test('uploads immediately when online', () async {
      final q = OfflineUploadQueue(uploader: MockImageUploadService());
      final result = await q.enqueue(sub('a'), Uint8List.fromList([1, 2, 3, 4]));
      expect(result.uploadStatus, UploadStatus.uploaded);
      expect(result.remoteUrl, isNotNull);
      expect(q.pending, isEmpty);
      await q.dispose();
    });

    test('retries and succeeds after transient failures', () async {
      // Fail the first attempt, then succeed on retry.
      final q = OfflineUploadQueue(
        uploader: MockImageUploadService(failTimes: 1),
        maxAttempts: 5,
      );
      await q.enqueue(sub('b'), Uint8List.fromList([1, 2, 3, 4]));
      await q.processPending(); // second pass succeeds
      expect(q.pending, isEmpty);
      await q.dispose();
    });

    test('holds items while offline, flushes when back online', () async {
      final q = OfflineUploadQueue(uploader: MockImageUploadService());
      q.setOnline(false);
      await q.enqueue(sub('c'), Uint8List.fromList([1, 2, 3, 4]));
      expect(q.pending, isNotEmpty);
      q.setOnline(true);
      await q.processPending();
      expect(q.pending, isEmpty);
      await q.dispose();
    });
  });

  group('DailyChallengeSnapshot reconcile', () {
    test('auto-completes at goal and never regresses', () {
      var snap = DailyChallengeSnapshot.fresh(
        participantId: 'u',
        challengeDay: 1,
        activityDate: '2026-07-31',
        stepGoal: 10000,
      );
      snap = snap.reconcileSteps(
        incomingSteps: 10450,
        method: VerificationMethod.automaticHealthSync,
        at: DateTime(2026, 7, 31, 20),
        reason: 'sync',
      );
      expect(snap.stepGoalCompleted, isTrue);
      expect(snap.adminVerificationStatus, AdminVerificationStatus.autoVerified);
      expect(snap.auditTrail.length, 1);

      // A later delayed sync reports fewer steps — must not un-complete.
      snap = snap.reconcileSteps(
        incomingSteps: 300,
        method: VerificationMethod.automaticHealthSync,
        at: DateTime(2026, 7, 31, 21),
        reason: 'delayed sync',
      );
      expect(snap.verifiedStepCount, 10450);
      expect(snap.stepGoalCompleted, isTrue);
      expect(snap.auditTrail.length, 2);
    });
  });

  group('MockHealthDataService', () {
    test('grants permission and returns steps; bumpToGoal crosses 10k', () async {
      final svc = MockHealthDataService();
      expect(await svc.requestPermissions(), isTrue);
      expect(await svc.getTodaySteps(), 8450);
      svc.bumpToGoal();
      expect(await svc.getTodaySteps() >= 10000, isTrue);
      expect(await svc.getLastSyncTime(), isNotNull);
    });
  });
}
