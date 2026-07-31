import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';

import { CONFIG, TASK_KEYS, BADGE_LABELS } from '../config';
import { db, FieldValue } from '../lib/admin';
import { addDays } from '../lib/time';
import { notifyParticipant } from '../lib/notify';

/// Server-authoritative scoring. Fires whenever a participant's daily doc
/// changes. Recomputes points from completed tasks, keeps the participant's
/// totalPoints in sync by delta, advances the streak the moment all five tasks
/// are done, and awards streak badges. Idempotent: writing pointsAwarded back
/// re-triggers this, but the delta is then 0 and it returns.
export const awardDailyPoints = onDocumentWritten(
  { document: 'participants/{uid}/days/{date}', region: CONFIG.region },
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return;

    const uid = event.params.uid as string;
    const date = event.params.date as string;
    const data = after.data() as Record<string, any>;

    const tasks = (data.tasks ?? {}) as Record<string, { completed?: boolean }>;
    const completedCount = TASK_KEYS.filter((k) => tasks[k]?.completed === true).length;
    const newPoints = completedCount * CONFIG.pointsPerTask;
    const prevPoints = (data.pointsAwarded as number | undefined) ?? 0;

    if (newPoints === prevPoints) return; // converged — nothing to do

    const nowAllComplete = completedCount === CONFIG.tasksPerDay;
    const wasAllComplete = prevPoints === CONFIG.dailyPointsTotal;

    let newStreak = 0;

    await db.runTransaction(async (tx) => {
      const pRef = db.doc(`participants/${uid}`);
      const pSnap = await tx.get(pRef);
      if (!pSnap.exists) return;
      const p = pSnap.data() as Record<string, any>;

      const delta = newPoints - prevPoints;
      const updates: Record<string, any> = {
        totalPoints: (p.totalPoints ?? 0) + delta,
        updatedAt: FieldValue.serverTimestamp(),
      };

      if (nowAllComplete && !wasAllComplete) {
        const last = p.lastCompletedDate as string | undefined;
        let streak = (p.streak as number | undefined) ?? 0;
        if (last === addDays(date, -1)) {
          streak += 1; // consecutive day
        } else if (last === date) {
          // already counted today — leave as is
        } else {
          streak = 1; // streak broken or first completion
        }
        newStreak = streak;
        updates.streak = streak;
        updates.lastCompletedDate = date;
      }

      tx.update(pRef, updates);
      tx.set(
        after.ref,
        { pointsAwarded: newPoints, scoredAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    });

    // Keep the server-authoritative daily snapshot in sync (ranking period
    // boards and weekly reports read from here). Snapshots are a SEPARATE
    // record from the raw day doc — this is the scored, auditable version.
    const stepsTask = (tasks['dailySteps'] ?? {}) as Record<string, any>;
    await db.doc(`participants/${uid}/snapshots/${date}`).set(
      {
        participantId: uid,
        challengeDay: (data.challengeDay as number | undefined) ?? null,
        activityDate: date,
        verifiedStepCount: (stepsTask.verifiedSteps as number | undefined) ?? 0,
        stepGoal: CONFIG.stepGoal,
        stepGoalCompleted: stepsTask.completed === true,
        verificationMethod: (stepsTask.method as string | undefined) ?? 'automaticHealthSync',
        pointsAwarded: newPoints,
        completionTime: nowAllComplete ? FieldValue.serverTimestamp() : null,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // Badges + celebration only when the day is freshly fully complete.
    if (nowAllComplete && !wasAllComplete) {
      await awardStreakBadges(uid, newStreak);
      await notifyParticipant(
        uid,
        'Day complete! 🎉',
        `+${CONFIG.dailyPointsTotal} points earned. Streak: ${newStreak} days. Keep it going!`,
        { type: 'dayComplete', date, streak: String(newStreak) },
      );
      logger.info(`Awarded full day to ${uid} on ${date}, streak=${newStreak}`);
    }
  },
);

async function awardStreakBadges(uid: string, streak: number): Promise<void> {
  const hit = CONFIG.streakBadges.find((t) => t === streak);
  if (!hit) return;
  const badgeId = `streak${hit}`;
  const ref = db.doc(`participants/${uid}/badges/${badgeId}`);
  const existing = await ref.get();
  if (existing.exists) return;
  await ref.set({
    id: badgeId,
    label: BADGE_LABELS[badgeId] ?? `${hit} Day Streak`,
    awardedAt: FieldValue.serverTimestamp(),
  });
  await notifyParticipant(
    uid,
    'Badge unlocked! 🏅',
    `You earned the "${BADGE_LABELS[badgeId] ?? `${hit} Day Streak`}" badge.`,
    { type: 'badge', badgeId },
  );
}
