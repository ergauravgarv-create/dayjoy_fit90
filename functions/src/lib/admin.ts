// Shared Firebase Admin singletons. Importing this initialises the default app
// exactly once, and exposes typed Firestore / Storage / FieldValue handles used
// across all functions.
import * as admin from 'firebase-admin';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

export { admin };
export const db = admin.firestore();
export const storage = admin.storage();
export const FieldValue = admin.firestore.FieldValue;
