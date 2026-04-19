import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore';
import { auth, db } from '../lib/firebase';

const FIRESTORE_WRITE_TIMEOUT_MS = 15000;

function capitalize(value) {
  if (!value) {
    return 'Record';
  }

  return value[0].toUpperCase() + value.slice(1);
}

function sanitizeForFirestore(values = {}) {
  return Object.fromEntries(
    Object.entries(values).filter(([, value]) => value !== undefined),
  );
}

function getActorMetadata() {
  const user = auth?.currentUser;
  const userId = user?.uid?.trim() ?? '';
  const userEmail = user?.email?.trim() ?? '';

  return {
    ...(userId ? { updatedByUid: userId } : {}),
    ...(userEmail ? { updatedByEmail: userEmail } : {}),
  };
}

function getCreateMetadata() {
  const actorMetadata = getActorMetadata();

  return {
    ...actorMetadata,
    ...(actorMetadata.updatedByUid ? { createdByUid: actorMetadata.updatedByUid } : {}),
    ...(actorMetadata.updatedByEmail ? { createdByEmail: actorMetadata.updatedByEmail } : {}),
  };
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

function resolveErrorMessage(error, action, itemLabel, collectionName) {
  const code = error?.code?.toString().trim().toLowerCase() ?? '';

  switch (code) {
    case 'permission-denied':
      return `You do not have permission to ${action} this ${itemLabel}.`;
    case 'unauthenticated':
      return 'Your admin session expired. Please sign in again.';
    case 'unavailable':
      return 'Firestore is temporarily unavailable. Please try again.';
    case 'not-found':
      return `This ${itemLabel} no longer exists in ${collectionName}.`;
    case 'failed-precondition':
      return `Firestore is missing required configuration for ${collectionName}.`;
    default:
      return error?.message || `Unable to ${action} ${itemLabel}.`;
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
    if (!db) {
      throw new Error('Firestore is not configured for the admin panel.');
    }

    return collection(db, collectionName);
  }

  return {
    subscribe({ onData, onError }) {
      try {
        const collectionRef = getCollectionRef();

        return onSnapshot(
          collectionRef,
          (snapshot) => {
            try {
              const records = snapshot.docs.map((record) =>
                typeof fromFirestore === 'function'
                  ? fromFirestore(record)
                  : { id: record.id, ...record.data() },
              );
              const sortedRecords =
                typeof sortRecords === 'function' ? [...records].sort(sortRecords) : records;

              onData?.(sortedRecords);
            } catch (error) {
              console.error(`Unable to map ${collectionName} data.`, error);
              onError?.(
                error?.message?.toString().trim() ||
                  `Unable to map ${capitalize(collectionName)} data from Firestore.`,
              );
            }
          },
          (error) => {
            console.error(`Unable to subscribe to ${collectionName}.`, error);
            onError?.(resolveErrorMessage(error, 'load', itemLabel, collectionName));
          },
        );
      } catch (error) {
        console.error(`Unable to initialize ${collectionName} subscription.`, error);
        onError?.(resolveErrorMessage(error, 'load', itemLabel, collectionName));
        return () => {};
      }
    },
    async create(values) {
      try {
        const payload = sanitizeForFirestore(
          typeof toFirestore === 'function' ? toFirestore(values) : values,
        );

        await withTimeout(
          addDoc(getCollectionRef(), {
            ...payload,
            ...getCreateMetadata(),
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
          }),
          `Saving the ${itemLabel} is taking too long. Check your Firestore rules or network connection and try again.`,
        );
      } catch (error) {
        console.error(`Unable to create ${itemLabel} in ${collectionName}.`, error);
        throw new Error(resolveErrorMessage(error, 'create', itemLabel, collectionName));
      }
    },
    async update(id, values) {
      if (!id) {
        throw new Error(`Unable to update ${itemLabel} because the ID is missing.`);
      }

      try {
        const payload = sanitizeForFirestore(
          typeof toFirestore === 'function' ? toFirestore(values) : values,
        );

        await withTimeout(
          updateDoc(doc(db, collectionName, id), {
            ...payload,
            ...getActorMetadata(),
            updatedAt: serverTimestamp(),
          }),
          `Updating the ${itemLabel} is taking too long. Check your Firestore rules or network connection and try again.`,
        );
      } catch (error) {
        console.error(`Unable to update ${itemLabel} ${id} in ${collectionName}.`, error);
        throw new Error(resolveErrorMessage(error, 'update', itemLabel, collectionName));
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
        console.error(`Unable to delete ${itemLabel} ${id} from ${collectionName}.`, error);
        throw new Error(resolveErrorMessage(error, 'delete', itemLabel, collectionName));
      }
    },
  };
}
