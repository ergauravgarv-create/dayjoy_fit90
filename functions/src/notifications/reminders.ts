import { onSchedule } from 'firebase-functions/v2/scheduler';

import { CONFIG, TASK_KEYS, TaskKey } from '../config';
import { db } from '../lib/admin';
import { localDateKey } from '../lib/time';
import { notifyMany } from '../lib/notify';

/// Remind everyone who hasn't yet completed a given task today. One
/// collection-group read for today's completion + one participants read.
async function sendTaskReminder(taskKey: TaskKey, title: string, body: string): Promise<void> {
  const today = localDateKey();

  const parts = await db.collection('participants').get();
  const daysSnap = await db.collectionGroup('days').where('activityDate', '==', today).get();

  const doneTask = new Map<string, Set<string>>();
  daysSnap.forEach((doc) => {
    const uid = doc.ref.parent.parent?.id;
    if (!uid) return;
    const tasks = (doc.get('tasks') ?? {}) as Record<string, { completed?: boolean }>;
    const set = new Set<string>();
    for (const k of TASK_KEYS) if (tasks[k]?.completed) set.add(k);
    doneTask.set(uid, set);
  });

  const uids = parts.docs
    .filter((d) => !(doneTask.get(d.id)?.has(taskKey) ?? false))
    .map((d) => d.id);

  if (uids.length) {
    await notifyMany(uids, title, body, { type: 'reminder', task: taskKey });
  }
}

const IST = { timeZone: CONFIG.timezone, region: CONFIG.region };

export const remindMorningYoga = onSchedule(
  { schedule: 'every day 06:30', ...IST },
  () => sendTaskReminder('morningYoga', '🧘 Morning Yoga time', 'Start your day right — capture your yoga session.'),
);

export const remindMorningShake = onSchedule(
  { schedule: 'every day 08:00', ...IST },
  () =>
    sendTaskReminder(
      'morningNutrition',
      '🥤 Morning nutrition',
      '25g Ample Meal Shake + 10g Vital Protein. Snap your selfie!',
    ),
);

export const remindWorkout = onSchedule(
  { schedule: 'every day 17:00', ...IST },
  () => sendTaskReminder('fitnessActivity', '💪 Time to move', 'Log today\'s workout — gym, walk, run, cycle or yoga.'),
);

export const remindSteps = onSchedule(
  { schedule: 'every day 19:00', ...IST },
  () => sendTaskReminder('dailySteps', '👟 Step goal check', `Close in on your ${CONFIG.stepGoal.toLocaleString()} steps today.`),
);

export const remindNightShake = onSchedule(
  { schedule: 'every day 21:30', ...IST },
  () =>
    sendTaskReminder(
      'nightNutrition',
      '🌙 Night nutrition',
      'Wrap up your day — 25g Ample Meal Shake + 10g Vital Protein.',
    ),
);

/// Weekly check-in nudge — Sundays 09:00 IST to all participants.
export const remindWeeklyCheckin = onSchedule(
  { schedule: 'every sunday 09:00', ...IST },
  async () => {
    const parts = await db.collection('participants').get();
    await notifyMany(
      parts.docs.map((d) => d.id),
      '⚖️ Weekly check-in',
      'Record your weight, waist and progress photos to see your transformation.',
      { type: 'weeklyCheckin' },
    );
  },
);

/// Daily motivational quote — 12:00 IST.
export const dailyMotivation = onSchedule(
  { schedule: 'every day 12:00', ...IST },
  async () => {
    const quotesSnap = await db.collection('quotes').get();
    const quotes = quotesSnap.docs.map((d) => (d.get('text') as string) ?? '').filter(Boolean);
    const fallback = 'Small steps every day lead to big changes every year.';
    const today = localDateKey();
    const dayNum = Number(today.slice(-2));
    const quote = quotes.length ? quotes[dayNum % quotes.length] : fallback;

    const parts = await db.collection('participants').get();
    await notifyMany(
      parts.docs.map((d) => d.id),
      '✨ Daily motivation',
      quote,
      { type: 'motivation' },
    );
  },
);
