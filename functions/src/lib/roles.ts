// Role helpers for callable functions. Roles live in the Auth custom claim
// `role` (authoritative for security rules) and are mirrored to `users/{uid}`.
import { HttpsError, CallableRequest } from 'firebase-functions/v2/https';

export type Role = 'participant' | 'coach' | 'doctor' | 'admin';

type Auth = CallableRequest['auth'];

/// The caller's role, or '' when unauthenticated / no role claim yet.
export function roleOf(auth: Auth): string {
  return (auth?.token?.role as string | undefined) ?? '';
}

/// Ensure the caller is signed in; returns the (non-null) auth context.
export function assertSignedIn(auth: Auth): NonNullable<Auth> {
  if (!auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  return auth;
}

/// Ensure the caller is an admin.
export function assertAdmin(auth: Auth): NonNullable<Auth> {
  const a = assertSignedIn(auth);
  if (roleOf(a) !== 'admin') {
    throw new HttpsError('permission-denied', 'Admin privileges required.');
  }
  return a;
}
