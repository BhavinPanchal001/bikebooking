import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore';
import { db, hasFirebaseConfig } from '../lib/firebase';

const FIRESTORE_WRITE_TIMEOUT_MS = 15000;

function capitalize(value) {
  if (!value) {
    return 'Record';
  }

  return value[0].toUpperCase() + value.slice(1);
}

function toFriendlyErrorMessage(error, action, itemLabel) {
  const code = error?.code?.toString().trim().toLowerCase() ?? '';
  const fallback = error?.message?.toString().trim();

  if (code === 'permission-denied') {
    return `You do not have permission to ${action} this ${itemLabel}.`;
  }

  if (code === 'unauthenticated') {
    return 'Your admin session expired. Please sign in again.';
  }

  if (code === 'unavailable') {
    return 'Firestore is temporarily unavailable. Please try again.';
  }

  if (code === 'failed-precondition') {
    return `Firestore is missing a required configuration to ${action} this ${itemLabel}.`;
  }

  if (code === 'not-found') {
    return `This ${itemLabel} no longer exists. Refresh and try again.`;
  }

  return fallback || `Unable to ${action} this ${itemLabel}.`;
}

async function withTimeout(promise, timeoutMessage, timeoutMs = FIRESTORE_WRITE_TIMEOUT_MS) {
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

export function createFirestoreCrudService({
  collectionName,
  fromFirestore,
  toFirestore,
  sortRecords,
  itemLabel = 'record',
}) {
  function getCollectionRef() {
    if (!hasFirebaseConfig || !db) {
      throw new Error('Firebase is not configured for the admin panel.');
    }

    return collection(db, collectionName);
  }

  return {
    subscribe({ onData, onError }) {
      if (!hasFirebaseConfig || !db) {
        onError?.('Firebase is not configured for the admin panel.');
        return () => {};
      }

      return onSnapshot(
        getCollectionRef(),
        (snapshot) => {
          try {
            const records = snapshot.docs.map((documentSnapshot) => fromFirestore(documentSnapshot));
            const sortedRecords = typeof sortRecords === 'function'
              ? [...records].sort(sortRecords)
              : records;
            onData?.(sortedRecords);
          } catch (error) {
            onError?.(
              error?.message?.toString().trim() ||
                `Unable to map ${capitalize(collectionName)} data from Firestore.`,
            );
          }
        },
        (error) => {
          onError?.(toFriendlyErrorMessage(error, 'load', itemLabel));
        },
      );
    },
    async create(values) {
      try {
        await withTimeout(
          addDoc(getCollectionRef(), {
            ...toFirestore(values),
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
          }),
          `Saving the ${itemLabel} is taking too long. Check your Firestore rules or network connection and try again.`,
        );
      } catch (error) {
        throw new Error(toFriendlyErrorMessage(error, 'create', itemLabel));
      }
    },
    async update(id, values) {
      if (!id) {
        throw new Error(`Unable to update ${itemLabel} because the ID is missing.`);
      }

      try {
        await withTimeout(
          updateDoc(doc(db, collectionName, id), {
            ...toFirestore(values),
            updatedAt: serverTimestamp(),
          }),
          `Updating the ${itemLabel} is taking too long. Check your Firestore rules or network connection and try again.`,
        );
      } catch (error) {
        throw new Error(toFriendlyErrorMessage(error, 'update', itemLabel));
      }
    },
    async remove(id) {
      if (!id) {
        throw new Error(`Unable to delete ${itemLabel} because the ID is missing.`);
      }

      try {
        await withTimeout(
          deleteDoc(doc(db, collectionName, id)),
          `Deleting the ${itemLabel} is taking too long. Check your Firestore rules or network connection and try again.`,
        );
      } catch (error) {
        throw new Error(toFriendlyErrorMessage(error, 'delete', itemLabel));
      }
    },
  };
}
