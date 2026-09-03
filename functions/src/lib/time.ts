// Date helpers keyed to India Standard Time (Asia/Kolkata, UTC+5:30, no DST).
// All keys are `yyyy-MM-dd` strings so they sort lexicographically and match the
// Flutter client's activityDate keys.

const IST_OFFSET_MIN = 330; // UTC+5:30

/// Today's date key (yyyy-MM-dd) in IST.
export function localDateKey(d: Date = new Date()): string {
  const ist = new Date(d.getTime() + IST_OFFSET_MIN * 60 * 1000);
  return ist.toISOString().slice(0, 10);
}

/// Add (or subtract, with a negative) days to a yyyy-MM-dd key.
export function addDays(key: string, days: number): string {
  const d = new Date(`${key}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/// Inclusive list of yyyy-MM-dd keys from [start] to [end].
export function dateRange(start: string, end: string): string[] {
  const out: string[] = [];
  let cur = start;
  // Cap the loop defensively so a bad range can never hang a function.
  for (let i = 0; i < 400 && cur <= end; i++) {
    out.push(cur);
    cur = addDays(cur, 1);
  }
  return out;
}

/// 1-based challenge week number for [endKey], counting from [startKey].
export function challengeWeek(startKey: string, endKey: string): number {
  const start = new Date(`${startKey}T00:00:00Z`).getTime();
  const end = new Date(`${endKey}T00:00:00Z`).getTime();
  const days = Math.floor((end - start) / (24 * 60 * 60 * 1000));
  return Math.max(1, Math.floor(days / 7) + 1);
}
