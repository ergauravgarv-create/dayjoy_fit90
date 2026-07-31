import { onCall, HttpsError } from 'firebase-functions/v2/https';

import { CONFIG } from '../config';
import { admin, db, FieldValue } from '../lib/admin';
import { assertAdmin, assertSignedIn, roleOf, Role } from '../lib/roles';

const ROLES: Role[] = ['participant', 'coach', 'doctor', 'admin'];

/// Admin-only: assign a role. Writes both the Auth custom claim (authoritative
/// for security rules) and the mirrored `users/{uid}` doc.
export const setUserRole = onCall({ region: CONFIG.region }, async (req) => {
  assertAdmin(req.auth);
  const uid = req.data?.uid as string;
  const role = req.data?.role as Role;
  if (!uid || !ROLES.includes(role)) {
    throw new HttpsError('invalid-argument', 'uid and a valid role are required.');
  }
  await admin.auth().setCustomUserClaims(uid, { role });
  await db.doc(`users/${uid}`).set(
    { role, roleUpdatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return { ok: true, uid, role };
});

/// Called by a freshly-signed-up user to self-assign the lowest-privilege
/// 'participant' role — but only if they don't already have a role (prevents a
/// coach/doctor/admin from downgrading themselves or escalating).
export const claimParticipantRole = onCall({ region: CONFIG.region }, async (req) => {
  const auth = assertSignedIn(req.auth);
  if (roleOf(auth) !== '') {
    return { ok: true, role: roleOf(auth) }; // already has a role — no-op
  }
  await admin.auth().setCustomUserClaims(auth.uid, { role: 'participant' });
  await db.doc(`users/${auth.uid}`).set(
    { uid: auth.uid, role: 'participant', createdAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return { ok: true, role: 'participant' };
});
