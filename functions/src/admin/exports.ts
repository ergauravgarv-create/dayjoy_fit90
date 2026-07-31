import { onCall } from 'firebase-functions/v2/https';

import { CONFIG } from '../config';
import { db, storage } from '../lib/admin';
import { assertAdmin } from '../lib/roles';

function csvCell(v: unknown): string {
  const s = v === null || v === undefined ? '' : String(v);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

/// Admin-only: export the participant roster to CSV, store it under
/// `exports/` in Cloud Storage, and return a 1-hour signed download URL.
/// (CSV opens directly in Excel/Sheets. For native .xlsx, add the `exceljs`
/// dependency and build a workbook here instead.)
export const exportParticipantsCsv = onCall({ region: CONFIG.region }, async (req) => {
  assertAdmin(req.auth);

  const header = [
    'participantId',
    'name',
    'mobile',
    'city',
    'distributor',
    'sponsorId',
    'startWeightKg',
    'currentWeightKg',
    'targetWeightKg',
    'streak',
    'totalPoints',
    'completionRate',
    'currentDay',
  ];

  const parts = await db.collection('participants').get();
  const rows: string[] = [header.join(',')];

  parts.forEach((doc) => {
    const p = doc.data() as Record<string, any>;
    rows.push(
      [
        doc.id,
        p.name,
        p.mobile,
        p.city,
        p.distributorName,
        p.sponsorId,
        p.startWeightKg,
        p.currentWeightKg,
        p.targetWeightKg,
        p.streak ?? 0,
        p.totalPoints ?? 0,
        p.completionRate ?? 0,
        p.currentDay ?? '',
      ]
        .map(csvCell)
        .join(','),
    );
  });

  const csv = rows.join('\n');
  const bucket = storage.bucket();
  const path = `exports/participants_${Date.now()}.csv`;
  const file = bucket.file(path);
  await file.save(csv, { contentType: 'text/csv; charset=utf-8' });

  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 60 * 60 * 1000, // 1 hour
  });

  return { url, path, count: parts.size };
});
