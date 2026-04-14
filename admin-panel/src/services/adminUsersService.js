import {
  collection,
  collectionGroup,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import { db, hasFirebaseConfig } from '../lib/firebase';

const FIRESTORE_WRITE_TIMEOUT_MS = 15000;

function toFriendlyErrorMessage(error, fallbackMessage) {
  const code = error?.code?.toString().trim().toLowerCase() ?? '';
  const fallback = error?.message?.toString().trim();

  if (code === 'permission-denied') {
    return 'You do not have permission to manage this user.';
  }

  if (code === 'unauthenticated') {
    return 'Your admin session expired. Please sign in again.';
  }

  if (code === 'not-found') {
    return 'This user no longer exists. Refresh and try again.';
  }

  if (code === 'unavailable') {
    return 'Firestore is temporarily unavailable. Please try again.';
  }

  return fallback || fallbackMessage;
}

async function withTimeout(
  promise,
  timeoutMessage,
  timeoutMs = FIRESTORE_WRITE_TIMEOUT_MS,
) {
  let timeoutId;

  const timeoutPromise = new Promise((_, reject) => {
    timeoutId = window.setTimeout(() => {
      reject(new Error(timeoutMessage));
    }, timeoutMs);
  });

  try {
    return await Promise.race([promise, timeoutPromise]);
  } finally {
    window.clearTimeout(timeoutId);
  }
}

function requireDb() {
  if (!hasFirebaseConfig || !db) {
    throw new Error('Firebase is not configured for the admin panel.');
  }

  return db;
}

async function deleteRefsInBatches(references) {
  if (references.length === 0) {
    return;
  }

  const uniqueRefs = Array.from(
    new Map(references.map((reference) => [reference.path, reference])).values(),
  );

  for (let index = 0; index < uniqueRefs.length; index += 450) {
    const batch = writeBatch(requireDb());
    const chunk = uniqueRefs.slice(index, index + 450);
    chunk.forEach((reference) => {
      batch.delete(reference);
    });
    await batch.commit();
  }
}

async function loadSnapshotRefs(snapshotPromise) {
  const snapshot = await snapshotPromise;
  return snapshot.docs.map((item) => item.ref);
}

async function loadChatCleanupRefs(database, userId) {
  const chatSnapshot = await getDocs(
    query(collection(database, 'chats'), where('participants', 'array-contains', userId)),
  );

  const refs = [];
  for (const chatDoc of chatSnapshot.docs) {
    refs.push(chatDoc.ref);
    const messagesSnapshot = await getDocs(collection(chatDoc.ref, 'messages'));
    messagesSnapshot.docs.forEach((messageDoc) => {
      refs.push(messageDoc.ref);
    });
  }

  return refs;
}

export const adminUsersService = {
  async blockUser({ userId, adminEmail }) {
    const database = requireDb();
    const userRef = doc(database, 'users', userId);

    await withTimeout(
      updateDoc(userRef, {
        adminBlocked: true,
        accountStatus: 'blocked',
        adminBlockedAt: serverTimestamp(),
        adminBlockedBy: adminEmail?.trim() || 'admin',
        updatedAt: serverTimestamp(),
      }),
      'Blocking this user is taking too long. Check your Firestore rules or network connection and try again.',
    ).catch((error) => {
      throw new Error(toFriendlyErrorMessage(error, 'Unable to block this user.'));
    });
  },

  async unblockUser({ userId }) {
    const database = requireDb();
    const userRef = doc(database, 'users', userId);

    await withTimeout(
      updateDoc(userRef, {
        adminBlocked: false,
        accountStatus: 'active',
        adminBlockedAt: deleteField(),
        adminBlockedBy: deleteField(),
        updatedAt: serverTimestamp(),
      }),
      'Unblocking this user is taking too long. Check your Firestore rules or network connection and try again.',
    ).catch((error) => {
      throw new Error(toFriendlyErrorMessage(error, 'Unable to unblock this user.'));
    });
  },

  async deleteUser({ userId }) {
    const database = requireDb();
    const trimmedUserId = userId?.trim() ?? '';

    if (!trimmedUserId) {
      throw new Error('Unable to delete this user because the ID is missing.');
    }

    const userRef = doc(database, 'users', trimmedUserId);
    const userSnapshot = await getDoc(userRef);

    if (!userSnapshot.exists()) {
      throw new Error('This user no longer exists. Refresh and try again.');
    }

    try {
      await withTimeout(
        Promise.all([
          loadSnapshotRefs(getDocs(collection(userRef, 'notifications'))),
          loadSnapshotRefs(getDocs(collection(userRef, 'favorites'))),
          loadSnapshotRefs(getDocs(collection(userRef, 'recentlyViewed'))),
          loadSnapshotRefs(getDocs(collection(userRef, 'reviews'))),
          loadSnapshotRefs(
            getDocs(
              query(
                collectionGroup(database, 'reviews'),
                where('reviewerId', '==', trimmedUserId),
              ),
            ),
          ),
          loadSnapshotRefs(
            getDocs(
              query(collection(database, 'seller_reports'), where('reporterId', '==', trimmedUserId)),
            ),
          ),
          loadSnapshotRefs(
            getDocs(
              query(collection(database, 'seller_reports'), where('sellerId', '==', trimmedUserId)),
            ),
          ),
          loadSnapshotRefs(
            getDocs(query(collection(database, 'products'), where('sellerId', '==', trimmedUserId))),
          ),
          loadSnapshotRefs(
            getDocs(
              query(collection(database, 'user_blocks'), where('blockerId', '==', trimmedUserId)),
            ),
          ),
          loadSnapshotRefs(
            getDocs(
              query(collection(database, 'user_blocks'), where('blockedUserId', '==', trimmedUserId)),
            ),
          ),
          loadChatCleanupRefs(database, trimmedUserId),
        ]).then(async (groups) => {
          const refs = groups.flat();
          await deleteRefsInBatches(refs);
          await deleteDoc(userRef);
        }),
        'Deleting this user is taking too long. Check your Firestore rules or network connection and try again.',
        30000,
      );
    } catch (error) {
      throw new Error(toFriendlyErrorMessage(error, 'Unable to delete this user.'));
    }
  },
};
