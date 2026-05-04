import {
  deleteDoc,
  doc,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore';
import { db } from '../lib/firebase';

const COLLECTION_NAME = 'products';

export const adminListingsService = {
  async approveListing({ listingId, adminEmail }) {
    if (!listingId) throw new Error('Listing ID is required');

    const listingRef = doc(db, COLLECTION_NAME, listingId);
    await updateDoc(listingRef, {
      adminReviewStatus: 'approved',
      moderatedAt: serverTimestamp(),
      moderatedBy: adminEmail || 'admin',
      updatedAt: serverTimestamp(),
    });
  },

  async flagListing({ listingId, adminEmail }) {
    if (!listingId) throw new Error('Listing ID is required');

    const listingRef = doc(db, COLLECTION_NAME, listingId);
    await updateDoc(listingRef, {
      adminReviewStatus: 'flagged',
      moderatedAt: serverTimestamp(),
      moderatedBy: adminEmail || 'admin',
      updatedAt: serverTimestamp(),
    });
  },

  async closeListing({ listingId, adminEmail }) {
    if (!listingId) throw new Error('Listing ID is required');

    const listingRef = doc(db, COLLECTION_NAME, listingId);
    await updateDoc(listingRef, {
      status: 'sold',
      adminReviewStatus: 'closed',
      moderatedAt: serverTimestamp(),
      moderatedBy: adminEmail || 'admin',
      updatedAt: serverTimestamp(),
    });
  },

  async reopenListing({ listingId, adminEmail }) {
    if (!listingId) throw new Error('Listing ID is required');

    const listingRef = doc(db, COLLECTION_NAME, listingId);
    await updateDoc(listingRef, {
      status: 'active',
      adminReviewStatus: 'approved',
      moderatedAt: serverTimestamp(),
      moderatedBy: adminEmail || 'admin',
      updatedAt: serverTimestamp(),
    });
  },

  async deleteListing({ listingId }) {
    if (!listingId) throw new Error('Listing ID is required');

    const listingRef = doc(db, COLLECTION_NAME, listingId);
    await deleteDoc(listingRef);
  },
};

