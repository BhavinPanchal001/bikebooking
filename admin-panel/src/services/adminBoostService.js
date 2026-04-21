import {
  collection,
  onSnapshot,
  orderBy,
  query,
  where,
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '../lib/firebase';

function ensureFirestore() {
  if (!db) {
    throw new Error('Firestore is not configured for the admin panel.');
  }
  return db;
}

function ensureFunctions() {
  if (!functions) {
    throw new Error('Cloud Functions client is not configured.');
  }
  return functions;
}

function toIsoString(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function snapshotToProduct(docSnap) {
  const data = docSnap.data() || {};
  const imageUrls = Array.isArray(data.imageUrls) ? data.imageUrls : [];
  return {
    id: docSnap.id,
    title: (data.title || '').toString().trim() || 'Untitled listing',
    brand: (data.brand || '').toString().trim(),
    category: (data.category || '').toString().trim(),
    sellerId: (data.sellerId || '').toString().trim(),
    sellerName: (data.sellerName || '').toString().trim() || 'Seller',
    price: Number.isFinite(Number(data.price)) ? Number(data.price) : 0,
    status: (data.status || 'active').toString().trim().toLowerCase(),
    primaryImage: imageUrls[0] || '',
    isBoosted: data.isBoosted === true,
    boostPlanId: (data.boostPlanId || '').toString().trim(),
    boostGrantSource: (data.boostGrantSource || '').toString().trim(),
    boostGrantedByEmail:
      (data.boostGrantedByEmail || '').toString().trim() || null,
    boostPaymentId: (data.boostPaymentId || '').toString().trim() || null,
    boostStartedAt: toIsoString(data.boostStartedAt),
    boostExpiresAt: toIsoString(data.boostExpiresAt),
    isEditorialFeatured: data.isEditorialFeatured === true,
    editorialFeaturedAt: toIsoString(data.editorialFeaturedAt),
    editorialFeaturedByEmail:
      (data.editorialFeaturedByEmail || '').toString().trim() || null,
    editorialFeaturedNote:
      (data.editorialFeaturedNote || '').toString().trim() || null,
    updatedAt: toIsoString(data.updatedAt),
  };
}

export const adminBoostService = {
  /**
   * Subscribes to the set of products where `isBoosted == true`. The
   * `clearExpiredBoosts` scheduled Function clears the flag within 15 min
   * of expiry, so this stream stays accurate without client-side filtering.
   */
  subscribeActiveBoosts({ onData, onError, pageSize = 200 }) {
    try {
      const firestore = ensureFirestore();
      const q = query(
        collection(firestore, 'products'),
        where('isBoosted', '==', true),
        orderBy('boostExpiresAt', 'asc'),
      );
      return onSnapshot(
        q,
        (snapshot) => {
          try {
            const records = snapshot.docs
              .map(snapshotToProduct)
              .slice(0, pageSize);
            onData?.(records);
          } catch (error) {
            onError?.(error?.message || 'Unable to read boosted listings.');
          }
        },
        (error) => {
          console.error('boost.subscribeActive', error);
          onError?.(error?.message || 'Unable to read boosted listings.');
        },
      );
    } catch (error) {
      onError?.(error?.message || 'Unable to read boosted listings.');
      return () => {};
    }
  },

  /**
   * Subscribes to editorially-featured products.
   */
  subscribeEditorialFeatured({ onData, onError, pageSize = 200 }) {
    try {
      const firestore = ensureFirestore();
      const q = query(
        collection(firestore, 'products'),
        where('isEditorialFeatured', '==', true),
        orderBy('editorialFeaturedAt', 'desc'),
      );
      return onSnapshot(
        q,
        (snapshot) => {
          try {
            const records = snapshot.docs
              .map(snapshotToProduct)
              .slice(0, pageSize);
            onData?.(records);
          } catch (error) {
            onError?.(error?.message || 'Unable to read featured listings.');
          }
        },
        (error) => {
          console.error('boost.subscribeFeatured', error);
          onError?.(error?.message || 'Unable to read featured listings.');
        },
      );
    } catch (error) {
      onError?.(error?.message || 'Unable to read featured listings.');
      return () => {};
    }
  },

  async grantBoost({ productId, durationDays, planSlug, note }) {
    const callable = httpsCallable(ensureFunctions(), 'adminGrantBoost');
    const result = await callable({
      productId,
      durationDays: Number(durationDays),
      planSlug: planSlug || undefined,
      note: note || undefined,
    });
    return result.data;
  },

  async extendBoost({ productId, additionalDays, note }) {
    const callable = httpsCallable(ensureFunctions(), 'adminExtendBoost');
    const result = await callable({
      productId,
      additionalDays: Number(additionalDays),
      note: note || undefined,
    });
    return result.data;
  },

  async revokeBoost({ productId, note }) {
    const callable = httpsCallable(ensureFunctions(), 'adminRevokeBoost');
    const result = await callable({ productId, note: note || undefined });
    return result.data;
  },

  async setEditorialFeatured({ productId, isFeatured, note }) {
    const callable = httpsCallable(
      ensureFunctions(),
      'adminSetEditorialFeatured',
    );
    const result = await callable({
      productId,
      isFeatured: Boolean(isFeatured),
      note: note || undefined,
    });
    return result.data;
  },
};
