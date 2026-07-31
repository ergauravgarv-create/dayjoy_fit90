import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { CONFIG } from '../config';
import { db } from '../lib/admin';
import { notifyParticipant, notifyUser } from '../lib/notify';

/// React to appointment lifecycle changes:
///  • new request  → notify the provider (coach/doctor)
///  • status change → notify the participant
export const onAppointmentWrite = onDocumentWritten(
  { document: 'appointments/{id}', region: CONFIG.region },
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return;
    const a = after.data() as Record<string, any>;
    const before = event.data?.before;
    const beforeData = before && before.exists ? (before.data() as Record<string, any>) : undefined;

    const participantId = a.participantId as string;
    const providerId = a.providerId as string;
    const providerName = (a.providerName as string) ?? 'your specialist';
    const type = (a.type as string) ?? 'session';

    if (!beforeData) {
      // Freshly created request.
      await notifyUser(
        providerId,
        'New appointment request',
        `A participant requested a ${type}.`,
        { type: 'appointmentRequest', appointmentId: event.params.id as string },
      );
      await notifyParticipant(
        participantId,
        'Request sent ✅',
        `Your ${type} request to ${providerName} was sent.`,
        { type: 'appointmentRequested', appointmentId: event.params.id as string },
      );
      return;
    }

    if (beforeData.status !== a.status) {
      const msg: Record<string, string> = {
        confirmed: `Your ${type} with ${providerName} is confirmed.`,
        rescheduled: `Your ${type} with ${providerName} was rescheduled.`,
        completed: `Your ${type} with ${providerName} is complete. Notes are available.`,
        cancelled: `Your ${type} with ${providerName} was cancelled.`,
      };
      await notifyParticipant(
        participantId,
        'Appointment update',
        msg[a.status as string] ?? `Your ${type} status: ${a.status}.`,
        { type: 'appointmentUpdate', appointmentId: event.params.id as string, status: String(a.status) },
      );
    }
  },
);

/// Remind both parties about appointments starting within the next hour.
export const appointmentReminders = onSchedule(
  { schedule: 'every 30 minutes', timeZone: CONFIG.timezone, region: CONFIG.region },
  async () => {
    const now = Date.now();
    const inOneHour = new Date(now + 60 * 60 * 1000);

    const snap = await db
      .collection('appointments')
      .where('status', '==', 'confirmed')
      .where('scheduledAt', '<=', inOneHour)
      .get();

    for (const doc of snap.docs) {
      const a = doc.data() as Record<string, any>;
      const scheduledAt = (a.scheduledAt as FirebaseFirestore.Timestamp | undefined)?.toDate();
      if (!scheduledAt || scheduledAt.getTime() < now) continue; // already passed
      if (a.reminderSent === true) continue;

      await notifyParticipant(
        a.participantId as string,
        'Upcoming appointment ⏰',
        `Your ${a.type ?? 'session'} starts soon.`,
        { type: 'appointmentReminder', appointmentId: doc.id },
      );
      await notifyUser(
        a.providerId as string,
        'Upcoming appointment ⏰',
        'You have a session starting within the hour.',
        { type: 'appointmentReminder', appointmentId: doc.id },
      );
      await doc.ref.set({ reminderSent: true }, { merge: true });
    }
  },
);
