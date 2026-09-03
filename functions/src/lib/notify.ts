// Notification helpers: write an in-app inbox document and push an FCM message
// to every device token on the target's profile. Device tokens are read from an
// `fcmTokens` string array on the user/participant doc; both locations are
// checked so either schema works. All failures are logged, never thrown — a
// missing token must not fail the calling function.
import { logger } from 'firebase-functions';

import { admin, db, FieldValue } from './admin';

type NotifData = Record<string, string>;

async function tokensFor(paths: string[]): Promise<string[]> {
  const tokens = new Set<string>();
  for (const path of paths) {
    try {
      const snap = await db.doc(path).get();
      const arr = (snap.get('fcmTokens') as string[] | undefined) ?? [];
      arr.forEach((t) => {
        if (t) tokens.add(t);
      });
    } catch (e) {
      logger.error(`token lookup failed for ${path}`, e);
    }
  }
  return [...tokens];
}

async function push(
  tokens: string[],
  title: string,
  body: string,
  data: NotifData,
): Promise<void> {
  if (tokens.length === 0) return;
  try {
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data,
    });
  } catch (e) {
    logger.error('FCM send failed', e);
  }
}

async function writeInbox(
  collectionPath: string,
  title: string,
  body: string,
  data: NotifData,
): Promise<void> {
  try {
    await db.collection(collectionPath).add({
      title,
      body,
      data,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    logger.error(`inbox write failed for ${collectionPath}`, e);
  }
}

/// Notify any user (coach / doctor / admin) by uid.
export async function notifyUser(
  uid: string,
  title: string,
  body: string,
  data: NotifData = {},
): Promise<void> {
  await writeInbox(`users/${uid}/notifications`, title, body, data);
  await push(await tokensFor([`users/${uid}`, `participants/${uid}`]), title, body, data);
}

/// Notify a participant by id.
export async function notifyParticipant(
  participantId: string,
  title: string,
  body: string,
  data: NotifData = {},
): Promise<void> {
  await writeInbox(`participants/${participantId}/notifications`, title, body, data);
  await push(
    await tokensFor([`participants/${participantId}`, `users/${participantId}`]),
    title,
    body,
    data,
  );
}

/// Notify many participants (used by scheduled broadcasts).
export async function notifyMany(
  uids: string[],
  title: string,
  body: string,
  data: NotifData = {},
): Promise<void> {
  await Promise.all(uids.map((uid) => notifyParticipant(uid, title, body, data)));
}
