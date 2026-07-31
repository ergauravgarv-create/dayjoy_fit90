import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';

import { CONFIG } from '../config';
import { db, FieldValue } from '../lib/admin';

/// Cross-checks each new photo submission's content hash against every other
/// submission (any participant). If the same image was submitted before, the
/// new submission is flagged for admin review and the event is audit-logged.
/// The client already blocks same-session duplicates; this catches cross-day
/// and cross-account reuse the device can't see.
export const onSubmissionCreated = onDocumentCreated(
  { document: 'participants/{uid}/submissions/{id}', region: CONFIG.region },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const s = snap.data() as Record<string, any>;
    const hash = s.imageHash as string | undefined;
    const uid = event.params.uid as string;
    if (!hash) return;

    const dupes = await db.collectionGroup('submissions').where('imageHash', '==', hash).get();
    const others = dupes.docs.filter((d) => d.ref.path !== snap.ref.path);
    if (others.length === 0) return;

    const first = others.sort((a, b) => {
      const at = (a.get('capturedAt') as FirebaseFirestore.Timestamp | undefined)?.toMillis() ?? 0;
      const bt = (b.get('capturedAt') as FirebaseFirestore.Timestamp | undefined)?.toMillis() ?? 0;
      return at - bt;
    })[0];

    await snap.ref.set(
      {
        duplicate: true,
        duplicateOf: first.ref.path,
        adminVerificationStatus: 'pending',
        flaggedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await db.collection('auditLogs').add({
      type: 'duplicatePhoto',
      participantId: uid,
      imageHash: hash,
      submissionPath: snap.ref.path,
      matchedPath: first.ref.path,
      at: FieldValue.serverTimestamp(),
    });

    logger.warn(`Duplicate photo flagged for ${uid}: ${hash}`);
  },
);
