import {
  deleteDoc,
  doc,
  onSnapshot,
  serverTimestamp,
  setDoc,
} from 'firebase/firestore';
import { auth, db } from '../lib/firebase';
import { feeConfigFromFirestore } from '../data/models/feeConfigMasterModel';

const COLLECTION = 'fee_config';

function collectionRef() {
  if (!db) {
    throw new Error('Firestore is not configured for the admin panel.');
  }
  return doc(db, COLLECTION, '__meta__').parent;
}

function getActorMetadata() {
  const user = auth?.currentUser;
  const uid = user?.uid?.trim() ?? '';
  const email = user?.email?.trim() ?? '';
  return {
    ...(uid ? { updatedByUid: uid } : {}),
    ...(email ? { updatedByEmail: email } : {}),
  };
}

function resolveError(error, action) {
  const code = error?.code?.toString().toLowerCase() ?? '';
  if (code === 'permission-denied') {
    return `You do not have admin permission to ${action} a fee.`;
  }
  if (code === 'unauthenticated') {
    return 'Your admin session expired. Please sign in again.';
  }
  return error?.message || `Unable to ${action} fee.`;
}

/**
 * Fee config docs are keyed by their slug (not a random id) so the mobile
 * app can look them up deterministically. We therefore use setDoc(slug) for
 * both create and update.
 */
export const feeConfigService = {
  subscribe({ onData, onError }) {
    try {
      const ref = collectionRef();
      return onSnapshot(
        ref,
        (snapshot) => {
          try {
            const records = snapshot.docs.map(feeConfigFromFirestore);
            records.sort((a, b) => {
              if (a.sortOrder !== b.sortOrder) {
                return (a.sortOrder ?? 0) - (b.sortOrder ?? 0);
              }
              return a.displayName.localeCompare(b.displayName);
            });
            onData?.(records);
          } catch (error) {
            onError?.(resolveError(error, 'load'));
          }
        },
        (error) => onError?.(resolveError(error, 'load')),
      );
    } catch (error) {
      onError?.(resolveError(error, 'load'));
      return () => {};
    }
  },
  async create(values) {
    if (!values.slug) {
      throw new Error('Slug is required.');
    }
    try {
      await setDoc(doc(db, COLLECTION, values.slug), {
        displayName: values.displayName,
        kind: values.kind,
        amountPaise: values.amountPaise,
        durationDays: values.durationDays ?? null,
        currency: values.currency || 'INR',
        sortOrder: values.sortOrder ?? 0,
        isActive: values.isActive !== false,
        subtitle: values.subtitle || '',
        ...getActorMetadata(),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
    } catch (error) {
      throw new Error(resolveError(error, 'create'));
    }
  },
  async update(id, values) {
    if (!id) {
      throw new Error('Fee slug is missing.');
    }
    try {
      await setDoc(
        doc(db, COLLECTION, id),
        {
          displayName: values.displayName,
          kind: values.kind,
          amountPaise: values.amountPaise,
          durationDays: values.durationDays ?? null,
          currency: values.currency || 'INR',
          sortOrder: values.sortOrder ?? 0,
          isActive: values.isActive !== false,
          subtitle: values.subtitle || '',
          ...getActorMetadata(),
          updatedAt: serverTimestamp(),
        },
        { merge: true },
      );
    } catch (error) {
      throw new Error(resolveError(error, 'update'));
    }
  },
  async delete(id) {
    if (!id) {
      throw new Error('Fee slug is missing.');
    }
    try {
      await deleteDoc(doc(db, COLLECTION, id));
    } catch (error) {
      throw new Error(resolveError(error, 'delete'));
    }
  },
};
