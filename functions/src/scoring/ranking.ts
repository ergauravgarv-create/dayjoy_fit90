import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions';

import { CONFIG } from '../config';
import { db, FieldValue } from '../lib/admin';
import { localDateKey, addDays } from '../lib/time';
import { assertAdmin } from '../lib/roles';

interface Entry {
  rank: number;
  participantId: string;
  name: string;
  city: string;
  photoUrl: string | null;
  points: number;
  streak: number;
  weightLostKg: number;
}

function toEntry(id: string, p: Record<string, any>, points: number): Omit<Entry, 'rank'> {
  const start = (p.startWeightKg as number) ?? 0;
  const current = (p.currentWeightKg as number) ?? start;
  return {
    participantId: id,
    name: (p.name as string) ?? 'Participant',
    city: (p.city as string) ?? '—',
    photoUrl: (p.photoUrl as string) ?? null,
    points,
    streak: (p.streak as number) ?? 0,
    weightLostKg: Math.max(0, +(start - current).toFixed(1)),
  };
}

function rank(entries: Omit<Entry, 'rank'>[]): Entry[] {
  return entries.slice(0, CONFIG.leaderboardSize).map((e, i) => ({ rank: i + 1, ...e }));
}

/// Rebuild every leaderboard variant + category from a single participants read
/// plus one snapshot collection-group scan for the period boards.
export async function buildAllLeaderboards(): Promise<void> {
  const today = localDateKey();

  // 1) Load all participants once.
  const partsSnap = await db.collection('participants').get();
  const participants = partsSnap.docs.map((d) => ({ id: d.id, data: d.data() as Record<string, any> }));

  // ---- Category boards derived directly from participant docs -------------
  const overall = rank(
    participants
      .map((p) => toEntry(p.id, p.data, (p.data.totalPoints as number) ?? 0))
      .sort((a, b) => b.points - a.points),
  );

  const highestStreak = rank(
    participants
      .map((p) => toEntry(p.id, p.data, (p.data.streak as number) ?? 0))
      .sort((a, b) => b.streak - a.streak),
  );

  const maxWeightLost = rank(
    participants
      .map((p) => toEntry(p.id, p.data, (p.data.totalPoints as number) ?? 0))
      .sort((a, b) => b.weightLostKg - a.weightLostKg),
  );

  const mostConsistent = rank(
    participants
      .map((p) => {
        const rate = (p.data.completionRate as number) ?? 0; // 0..1 maintained by weekly report
        return { ...toEntry(p.id, p.data, Math.round(rate * 100)) };
      })
      .sort((a, b) => b.points - a.points),
  );

  // ---- Period boards from snapshot points within a date window ------------
  const daily = await periodBoard(participants, today, today);
  const weekly = await periodBoard(participants, addDays(today, -6), today);
  const monthly = await periodBoard(participants, addDays(today, -29), today);

  // ---- City & distributor rollups ----------------------------------------
  const cities = groupBoard(participants, (p) => (p.data.city as string) ?? '—');
  const distributors = groupBoard(participants, (p) => (p.data.distributorName as string) ?? '—');

  // ---- Persist ------------------------------------------------------------
  const write = (id: string, payload: unknown) =>
    db.doc(`leaderboards/${id}`).set(
      { entries: payload, updatedAt: FieldValue.serverTimestamp(), day: today },
      { merge: true },
    );

  await Promise.all([
    write('overall', overall),
    write('highestStreak', highestStreak),
    write('maxWeightLost', maxWeightLost),
    write('mostConsistent', mostConsistent),
    write('daily', daily),
    write('weekly', weekly),
    write('monthly', monthly),
    write('cities', cities),
    write('distributors', distributors),
  ]);

  logger.info(`Leaderboards rebuilt for ${participants.length} participants.`);
}

async function periodBoard(
  participants: { id: string; data: Record<string, any> }[],
  start: string,
  end: string,
): Promise<Entry[]> {
  const pById = new Map(participants.map((p) => [p.id, p.data]));
  const points = new Map<string, number>();

  const snap = await db
    .collectionGroup('snapshots')
    .where('activityDate', '>=', start)
    .where('activityDate', '<=', end)
    .get();

  snap.forEach((doc) => {
    const s = doc.data() as Record<string, any>;
    const pid = s.participantId as string | undefined;
    if (!pid) return;
    points.set(pid, (points.get(pid) ?? 0) + ((s.pointsAwarded as number) ?? 0));
  });

  const entries = [...points.entries()]
    .filter(([id]) => pById.has(id))
    .map(([id, pts]) => toEntry(id, pById.get(id)!, pts))
    .sort((a, b) => b.points - a.points);

  return rank(entries);
}

function groupBoard(
  participants: { id: string; data: Record<string, any> }[],
  keyFn: (p: { id: string; data: Record<string, any> }) => string,
): { rank: number; group: string; points: number; members: number }[] {
  const groups = new Map<string, { points: number; members: number }>();
  for (const p of participants) {
    const key = keyFn(p);
    const g = groups.get(key) ?? { points: 0, members: 0 };
    g.points += (p.data.totalPoints as number) ?? 0;
    g.members += 1;
    groups.set(key, g);
  }
  return [...groups.entries()]
    .map(([group, g]) => ({ group, ...g }))
    .sort((a, b) => b.points - a.points)
    .slice(0, CONFIG.leaderboardSize)
    .map((g, i) => ({ rank: i + 1, ...g }));
}

/// Scheduled hourly rebuild.
export const rebuildLeaderboards = onSchedule(
  { schedule: 'every 60 minutes', timeZone: CONFIG.timezone, region: CONFIG.region },
  async () => {
    await buildAllLeaderboards();
  },
);

/// Admin-triggered manual rebuild.
export const rebuildLeaderboardsNow = onCall({ region: CONFIG.region }, async (req) => {
  assertAdmin(req.auth);
  await buildAllLeaderboards();
  return { ok: true };
});
