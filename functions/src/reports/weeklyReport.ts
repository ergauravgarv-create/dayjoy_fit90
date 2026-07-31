import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions';

import { CONFIG } from '../config';
import { db, FieldValue } from '../lib/admin';
import { localDateKey, addDays, dateRange, challengeWeek } from '../lib/time';
import { assertAdmin } from '../lib/roles';
import { notifyParticipant } from '../lib/notify';

interface WeeklyReport {
  weekId: string;
  weekNumber: number;
  startDate: string;
  endDate: string;
  daysCompleted: number;
  daysInWeek: number;
  completionRate: number; // 0..1
  totalSteps: number;
  activeCalories: number;
  workoutMinutes: number;
  startWeightKg: number | null;
  endWeightKg: number | null;
  weightChangeKg: number | null;
  bmi: number | null;
  bmiChange: number | null;
  pointsEarned: number;
  generatedAt: FirebaseFirestore.FieldValue;
}

/// Build one participant's report for the 7-day window ending at [endDate].
export async function buildWeeklyReport(uid: string, endDate: string): Promise<WeeklyReport | null> {
  const pRef = db.doc(`participants/${uid}`);
  const pSnap = await pRef.get();
  if (!pSnap.exists) return null;
  const p = pSnap.data() as Record<string, any>;

  const startDate = addDays(endDate, -6);
  const days = dateRange(startDate, endDate);
  // participant.startDate may be a Timestamp or an ISO string — normalise to
  // a yyyy-MM-dd key.
  const rawStart = p.startDate;
  const startKey =
    typeof rawStart === 'string' && rawStart.length >= 10 ? rawStart.slice(0, 10) : startDate;
  const weekNumber = challengeWeek(startKey, endDate);
  const weekId = `week-${String(weekNumber).padStart(2, '0')}`;

  // Aggregate the week's snapshots (steps + points) and health syncs (calories).
  let totalSteps = 0;
  let activeCalories = 0;
  let workoutMinutes = 0;
  let daysCompleted = 0;
  let pointsEarned = 0;

  const snapSnap = await db
    .collection(`participants/${uid}/snapshots`)
    .where('activityDate', '>=', startDate)
    .where('activityDate', '<=', endDate)
    .get();
  snapSnap.forEach((doc) => {
    const s = doc.data() as Record<string, any>;
    totalSteps += (s.verifiedStepCount as number) ?? 0;
    pointsEarned += (s.pointsAwarded as number) ?? 0;
  });

  const daySnap = await db
    .collection(`participants/${uid}/days`)
    .where('activityDate', '>=', startDate)
    .where('activityDate', '<=', endDate)
    .get();
  daySnap.forEach((doc) => {
    const d = doc.data() as Record<string, any>;
    if (((d.pointsAwarded as number) ?? 0) >= CONFIG.dailyPointsTotal) daysCompleted += 1;
  });

  const hsSnap = await db
    .collection(`participants/${uid}/healthSyncs`)
    .where('localDate', '>=', startDate)
    .where('localDate', '<=', endDate)
    .get();
  hsSnap.forEach((doc) => {
    const h = doc.data() as Record<string, any>;
    activeCalories += (h.activeCalories as number) ?? 0;
    workoutMinutes += (h.workoutMinutes as number) ?? 0;
  });

  // Weight & BMI from this week's and last week's check-ins.
  const heightM = (((p.heightCm as number) ?? 0) / 100) || null;
  const thisCheckin = await db.doc(`participants/${uid}/weeklyCheckins/${weekId}`).get();
  const prevWeekId = `week-${String(Math.max(1, weekNumber - 1)).padStart(2, '0')}`;
  const prevCheckin = await db.doc(`participants/${uid}/weeklyCheckins/${prevWeekId}`).get();

  const endWeight =
    (thisCheckin.get('weightKg') as number | undefined) ?? (p.currentWeightKg as number | undefined) ?? null;
  const startWeight =
    (prevCheckin.get('weightKg') as number | undefined) ?? (p.startWeightKg as number | undefined) ?? null;

  const bmi = heightM && endWeight ? +(endWeight / (heightM * heightM)).toFixed(1) : null;
  const prevBmi = heightM && startWeight ? startWeight / (heightM * heightM) : null;
  const bmiChange = bmi !== null && prevBmi !== null ? +(bmi - prevBmi).toFixed(1) : null;
  const weightChange =
    endWeight !== null && startWeight !== null ? +(endWeight - startWeight).toFixed(1) : null;

  const report: WeeklyReport = {
    weekId,
    weekNumber,
    startDate,
    endDate,
    daysCompleted,
    daysInWeek: days.length,
    completionRate: +(daysCompleted / days.length).toFixed(3),
    totalSteps,
    activeCalories: Math.round(activeCalories),
    workoutMinutes,
    startWeightKg: startWeight,
    endWeightKg: endWeight,
    weightChangeKg: weightChange,
    bmi,
    bmiChange,
    pointsEarned,
    generatedAt: FieldValue.serverTimestamp(),
  };

  await db.doc(`participants/${uid}/weeklyReports/${weekId}`).set(report, { merge: true });

  // Maintain a rolling completionRate on the participant for the "Most
  // Consistent" leaderboard.
  await pRef.set({ completionRate: report.completionRate }, { merge: true });

  return report;
}

/// Weekly batch — Mondays 07:00 IST — report for every participant.
export const generateWeeklyReports = onSchedule(
  { schedule: 'every monday 07:00', timeZone: CONFIG.timezone, region: CONFIG.region },
  async () => {
    const end = addDays(localDateKey(), -1); // the week that just ended (Sun)
    const parts = await db.collection('participants').get();
    for (const doc of parts.docs) {
      try {
        const report = await buildWeeklyReport(doc.id, end);
        if (report) {
          await notifyParticipant(
            doc.id,
            'Your weekly report is ready 📊',
            `Week ${report.weekNumber}: ${report.daysCompleted}/${report.daysInWeek} days, ` +
              `${report.totalSteps.toLocaleString()} steps` +
              (report.weightChangeKg !== null ? `, ${report.weightChangeKg} kg` : ''),
            { type: 'weeklyReport', weekId: report.weekId },
          );
        }
      } catch (e) {
        logger.error(`weekly report failed for ${doc.id}`, e);
      }
    }
  },
);

/// On-demand report (admin, or a participant regenerating their own).
export const generateMyWeeklyReport = onCall({ region: CONFIG.region }, async (req) => {
  const uid = (req.data?.participantId as string) ?? req.auth?.uid;
  if (!uid) throw new Error('participantId required');
  // Only self or admin.
  if (req.auth?.uid !== uid) assertAdmin(req.auth);
  const end = (req.data?.endDate as string) ?? localDateKey();
  const report = await buildWeeklyReport(uid, end);
  return { report };
});
