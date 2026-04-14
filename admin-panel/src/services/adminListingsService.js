import {
  collection,
  collectionGroup,
  deleteDoc,
  doc,
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
    return 'You do not have permission to manage this listing.';
  }

  if (code === 'unauthenticated') {
    return 'Your admin session expired. Please sign in again.';
  }

  if (code === 'not-found') {
    return 'This listing no longer exists. Refresh and try again.';
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

async function loadChatCleanupRefs(database, listingId) {
  const chatSnapshot = await getDocs(
    query(collection(database, 'chats'), where('productSnapshot.productId', '==', listingId)),
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

async function updateListing(listingId, patch, timeoutMessage, fallbackMessage) {
  const database = requireDb();

  try {
    await withTimeout(
      updateDoc(doc(database, 'products', listingId), {
        ...patch,
        updatedAt: serverTimestamp(),
      }),
      timeoutMessage,
    );
  } catch (error) {
    throw new Error(toFriendlyErrorMessage(error, fallbackMessage));
  }
}

export const adminListingsService = {
  async approveListing({ listingId, adminEmail }) {
    await updateListing(
      listingId,
      {
        status: 'active',
        adminReviewStatus: 'approved',
        moderatedAt: serverTimestamp(),
        moderatedBy: adminEmail?.trim() || 'admin',
      },
      'Approving this listing is taking too long. Check your Firestore rules or network connection and try again.',
      'Unable to approve this listing.',
    );
  },

  async flagListing({ listingId, adminEmail }) {
    await updateListing(
      listingId,
      {
        adminReviewStatus: 'flagged',
        moderatedAt: serverTimestamp(),
        moderatedBy: adminEmail?.trim() || 'admin',
      },
      'Flagging this listing is taking too long. Check your Firestore rules or network connection and try again.',
      'Unable to flag this listing.',
    );
  },

  async closeListing({ listingId, adminEmail }) {
    await updateListing(
      listingId,
      {
        status: 'sold',
        adminReviewStatus: 'closed',
        moderatedAt: serverTimestamp(),
        moderatedBy: adminEmail?.trim() || 'admin',
      },
      'Closing this listing is taking too long. Check your Firestore rules or network connection and try again.',
      'Unable to close this listing.',
    );
  },

  async reopenListing({ listingId, adminEmail }) {
    await updateListing(
      listingId,
      {
        status: 'active',
        adminReviewStatus: 'approved',
        moderatedAt: serverTimestamp(),
        moderatedBy: adminEmail?.trim() || 'admin',
      },
      'Reopening this listing is taking too long. Check your Firestore rules or network connection and try again.',
      'Unable to reopen this listing.',
    );
  },

  async deleteListing({ listingId }) {
    const database = requireDb();
    const trimmedListingId = listingId?.trim() ?? '';

    if (!trimmedListingId) {
      throw new Error('Unable to delete this listing because the ID is missing.');
    }

    try {
      await withTimeout(
        Promise.all([
          loadSnapshotRefs(
            getDocs(
              query(
                collectionGroup(database, 'favorites'),
                where('productId', '==', trimmedListingId),
              ),
            ),
          ),
          loadSnapshotRefs(
            getDocs(
              query(
                collectionGroup(database, 'recentlyViewed'),
                where('productId', '==', trimmedListingId),
              ),
            ),
          ),
          loadChatCleanupRefs(database, trimmedListingId),
        ]).then(async (groups) => {
          await deleteRefsInBatches(groups.flat());
          await deleteDoc(doc(database, 'products', trimmedListingId));
        }),
        'Deleting this listing is taking too long. Check your Firestore rules or network connection and try again.',
        30000,
      );
    } catch (error) {
      throw new Error(toFriendlyErrorMessage(error, 'Unable to delete this listing.'));
    }
  },
};
