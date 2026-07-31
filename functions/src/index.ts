import { setGlobalOptions } from 'firebase-functions/v2';
import { CONFIG } from './config';

// Default region for every function (Mumbai). Individual functions may override.
setGlobalOptions({ region: CONFIG.region, maxInstances: 20 });

// --- Scoring -----------------------------------------------------------------
export { awardDailyPoints } from './scoring/awardDailyPoints';
export { rebuildLeaderboards, rebuildLeaderboardsNow } from './scoring/ranking';

// --- Reports -----------------------------------------------------------------
export { generateWeeklyReports, generateMyWeeklyReport } from './reports/weeklyReport';

// --- Notifications -----------------------------------------------------------
export {
  remindMorningYoga,
  remindMorningShake,
  remindWorkout,
  remindSteps,
  remindNightShake,
  remindWeeklyCheckin,
  dailyMotivation,
} from './notifications/reminders';
export { onAppointmentWrite, appointmentReminders } from './notifications/appointments';

// --- Media integrity ---------------------------------------------------------
export { onSubmissionCreated } from './media/duplicateGuard';

// --- Admin -------------------------------------------------------------------
export { setUserRole, claimParticipantRole } from './admin/roles';
export { exportParticipantsCsv } from './admin/exports';
