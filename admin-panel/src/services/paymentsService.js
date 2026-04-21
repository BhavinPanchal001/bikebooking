import {
  collection,
  doc,
  getDocs,
  limit as limitFn,
  onSnapshot,
  orderBy,
  query,
  startAfter,
  where,
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '../lib/firebase';

const COLLECTION = 'payments';

function snapshotToRecord(docSnap) {
  const data = docSnap.data() || {};
  const razorpay = data.razorpay || {};
  return {
    id: docSnap.id,
    kind: data.kind || '',
    status: data.status || 'created',
    userId: data.userId || null,
    userEmail: data.userEmail || null,
    amountPaise: Number.parseInt(data.amountPaise, 10) || 0,
    currency: data.currency || 'INR',
    razorpayOrderId: razorpay.orderId || null,
    razorpayPaymentId: razorpay.paymentId || null,
    paymentMethod: razorpay.method || null,
    errorCode: razorpay.errorCode || null,
    errorDescription: razorpay.errorDescription || null,
    target: data.target || null,
    metadata: data.metadata || {},
    refunds: Array.isArray(data.refunds) ? data.refunds : [],
    webhookEventIds: Array.isArray(data.webhookEventIds)
      ? data.webhookEventIds
      : [],
    createdAt: data.createdAt?.toDate?.().toISOString() ?? null,
    updatedAt: data.updatedAt?.toDate?.().toISOString() ?? null,
    paidAt: data.paidAt?.toDate?.().toISOString() ?? null,
    failedAt: data.failedAt?.toDate?.().toISOString() ?? null,
    refundedAt: data.refundedAt?.toDate?.().toISOString() ?? null,
    raw: data,
  };
}

function buildConstraints({ statusFilter, kindFilter }) {
  const constraints = [];
  if (kindFilter && kindFilter !== 'all') {
    constraints.push(where('kind', '==', kindFilter));
  }
  if (statusFilter && statusFilter !== 'all') {
    constraints.push(where('status', '==', statusFilter));
  }
  constraints.push(orderBy('createdAt', 'desc'));
  return constraints;
}

export const paymentsService = {
  /**
   * Subscribes to the first `pageSize` payments (sorted by createdAt desc).
   * For deep pagination use `fetchPage` instead — onSnapshot with startAfter
   * is finicky when the cursor doc changes between pages.
   */
  subscribeFirstPage({ statusFilter, kindFilter, pageSize = 50, onData, onError }) {
    if (!db) {
      onError?.('Firestore is not configured for the admin panel.');
      return () => {};
    }
    try {
      const q = query(
        collection(db, COLLECTION),
        ...buildConstraints({ statusFilter, kindFilter }),
        limitFn(pageSize),
      );
      return onSnapshot(
        q,
        (snapshot) => {
          try {
            onData?.(snapshot.docs.map(snapshotToRecord));
          } catch (error) {
            onError?.(error?.message || 'Unable to read payments.');
          }
        },
        (error) => {
          console.error('payments.subscribeFirstPage', error);
          onError?.(error?.message || 'Unable to read payments.');
        },
      );
    } catch (error) {
      onError?.(error?.message || 'Unable to read payments.');
      return () => {};
    }
  },

  async fetchPage({ statusFilter, kindFilter, pageSize = 50, afterRecord }) {
    if (!db) {
      throw new Error('Firestore is not configured for the admin panel.');
    }
    const constraints = buildConstraints({ statusFilter, kindFilter });
    if (afterRecord?.raw?.createdAt) {
      constraints.push(startAfter(afterRecord.raw.createdAt));
    }
    constraints.push(limitFn(pageSize));

    const q = query(collection(db, COLLECTION), ...constraints);
    const snapshot = await getDocs(q);
    return snapshot.docs.map(snapshotToRecord);
  },

  async refund({ paymentId, amountPaise, reason }) {
    if (!functions) {
      throw new Error('Cloud Functions client is not configured.');
    }
    const callable = httpsCallable(functions, 'refundPayment');
    const payload = { paymentId, reason: reason || '' };
    if (Number.isFinite(Number(amountPaise)) && Number(amountPaise) > 0) {
      payload.amountPaise = Number(amountPaise);
    }
    const result = await callable(payload);
    return result.data;
  },
};
