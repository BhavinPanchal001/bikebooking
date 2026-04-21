const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {HttpsError} = require("firebase-functions/v2/https");

const {requireAuth, requireAdmin} = require("./admin");
const {writeAuditLog} = require("./audit");
const {loadFeeConfig} = require("./feeConfig");
const {
  getRazorpayClient,
  getKeyId,
  verifyCheckoutSignature,
} = require("./razorpay");
const {
  applyPaymentSideEffect,
  reversePaymentSideEffect,
} = require("./sideEffects");

const PAYMENTS = "payments";

/**
 * Callable: createPaymentOrder
 *
 * Input: {
 *   feeSlug: string,                 // key in /fee_config
 *   target?: { type: "product" | "user", id: string },
 *   metadata?: Record<string,string>
 * }
 *
 * Output: {
 *   paymentId: string,               // our /payments/{id}
 *   razorpayOrderId: string,
 *   razorpayKeyId: string,           // safe to expose (publishable)
 *   amountPaise: number,
 *   currency: "INR",
 * }
 */
async function createPaymentOrderHandler(request) {
  const auth = requireAuth(request);
  const {feeSlug, target, metadata} = request.data || {};

  const fee = await loadFeeConfig(feeSlug);

  if (target) {
    if (typeof target !== "object" ||
        !target.type ||
        !target.id ||
        typeof target.id !== "string") {
      throw new HttpsError("invalid-argument", "target is malformed.");
    }
  }

  const db = getFirestore();
  const docRef = db.collection(PAYMENTS).doc();
  const receipt = `pay_${docRef.id}`.slice(0, 40);

  const client = getRazorpayClient();
  let order;
  try {
    order = await client.orders.create({
      amount: fee.amountPaise,
      currency: fee.currency,
      receipt,
      notes: {
        paymentDocId: docRef.id,
        userId: auth.uid,
        feeSlug: fee.slug,
        kind: fee.kind,
        targetType: (target && target.type) || "",
        targetId: (target && target.id) || "",
      },
    });
  } catch (error) {
    console.error("Razorpay order create failed", error);
    throw new HttpsError(
      "internal",
      "Could not create Razorpay order. Please retry.",
    );
  }

  const now = FieldValue.serverTimestamp();
  const sanitizedMetadata = sanitizeMetadata(metadata);
  sanitizedMetadata.feeSlug = fee.slug;
  if (fee.durationDays) {
    sanitizedMetadata.durationDays = String(fee.durationDays);
  }

  await docRef.set({
    kind: fee.kind,
    status: "created",
    userId: auth.uid,
    userEmail: (auth.token && auth.token.email) || null,
    amountPaise: fee.amountPaise,
    currency: fee.currency,
    razorpay: {
      orderId: order.id,
      paymentId: null,
      signature: null,
      method: null,
      errorCode: null,
      errorDescription: null,
    },
    target: target || null,
    metadata: sanitizedMetadata,
    refunds: [],
    webhookEventIds: [],
    createdAt: now,
    updatedAt: now,
    paidAt: null,
    failedAt: null,
    refundedAt: null,
  });

  return {
    paymentId: docRef.id,
    razorpayOrderId: order.id,
    razorpayKeyId: getKeyId(),
    amountPaise: fee.amountPaise,
    currency: fee.currency,
  };
}

/**
 * Callable: verifyPaymentSignature
 *
 * Called by the client right after the Razorpay checkout reports success.
 * Verifies the HMAC signature, fetches the payment server-side to confirm
 * amount/status, applies the side-effect (boost, listing-fee), and marks
 * our /payments/{id} doc as `paid`.
 */
async function verifyPaymentSignatureHandler(request) {
  const auth = requireAuth(request);
  const {
    paymentId,
    razorpayOrderId,
    razorpayPaymentId,
    razorpaySignature,
  } = request.data || {};

  if (!paymentId || !razorpayOrderId ||
      !razorpayPaymentId || !razorpaySignature) {
    throw new HttpsError(
      "invalid-argument",
      "paymentId, razorpayOrderId, razorpayPaymentId, and razorpaySignature " +
        "are all required.",
    );
  }

  const db = getFirestore();
  const ref = db.collection(PAYMENTS).doc(String(paymentId));
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Payment record not found.");
  }

  const payment = Object.assign({id: snap.id}, snap.data() || {});
  if (payment.userId !== auth.uid) {
    throw new HttpsError(
      "permission-denied",
      "You can only confirm your own payments.",
    );
  }
  if (payment.razorpay && payment.razorpay.orderId !== razorpayOrderId) {
    throw new HttpsError(
      "failed-precondition",
      "Order id does not match the payment record.",
    );
  }

  // Already paid? Idempotent re-entry.
  if (payment.status === "paid" || payment.status === "refunded" ||
      payment.status === "partially_refunded") {
    return {status: payment.status, paymentId};
  }

  const signatureOk = verifyCheckoutSignature({
    orderId: razorpayOrderId,
    paymentId: razorpayPaymentId,
    signature: razorpaySignature,
  });
  if (!signatureOk) {
    await ref.set({
      status: "failed",
      failedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      razorpay: Object.assign({}, payment.razorpay || {}, {
        errorCode: "signature_mismatch",
        errorDescription: "Checkout signature did not match.",
      }),
    }, {merge: true});
    throw new HttpsError(
      "permission-denied",
      "Payment signature verification failed.",
    );
  }

  // Fetch from Razorpay to double-check amount/status.
  const client = getRazorpayClient();
  let rpPayment;
  try {
    rpPayment = await client.payments.fetch(razorpayPaymentId);
  } catch (error) {
    console.error("Razorpay payments.fetch failed", error);
    throw new HttpsError(
      "internal",
      "Could not verify payment with Razorpay.",
    );
  }

  const amountOk = Number(rpPayment.amount) === Number(payment.amountPaise);
  const orderOk = rpPayment.order_id === razorpayOrderId;
  const captured = rpPayment.status === "captured" ||
    rpPayment.status === "authorized";
  if (!amountOk || !orderOk || !captured) {
    await ref.set({
      status: "failed",
      failedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      razorpay: Object.assign({}, payment.razorpay || {}, {
        errorCode: "integrity_failed",
        errorDescription:
          `amountOk=${amountOk} orderOk=${orderOk} status=${rpPayment.status}`,
      }),
    }, {merge: true});
    throw new HttpsError(
      "failed-precondition",
      "Payment could not be verified. Please contact support.",
    );
  }

  const updated = {
    status: "paid",
    paidAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    razorpay: Object.assign({}, payment.razorpay || {}, {
      paymentId: razorpayPaymentId,
      signature: razorpaySignature,
      method: rpPayment.method || null,
      errorCode: null,
      errorDescription: null,
    }),
  };
  await ref.set(updated, {merge: true});

  // Apply side-effect (boost, listing fee, ...).
  const hydrated = Object.assign({}, payment, updated);
  try {
    await applyPaymentSideEffect(db, hydrated);
  } catch (error) {
    console.error("Side-effect failed for payment", paymentId, error);
    // Do not fail the callable — webhook will retry. Audit instead.
    await writeAuditLog({
      action: "payment.side_effect_failed",
      actorUid: auth.uid,
      actorEmail: (auth.token && auth.token.email) || null,
      entityType: "payment",
      entityId: paymentId,
      metadata: {
        error: error instanceof Error ? error.message : String(error),
      },
    });
  }

  await writeAuditLog({
    action: "payment.verified",
    actorUid: auth.uid,
    actorEmail: (auth.token && auth.token.email) || null,
    entityType: "payment",
    entityId: paymentId,
    metadata: {
      kind: payment.kind,
      amountPaise: payment.amountPaise,
      razorpayPaymentId,
    },
  });

  return {status: "paid", paymentId};
}

/**
 * Callable: refundPayment (admin-only)
 *
 * Input: { paymentId, amountPaise?, reason? }
 * amountPaise omitted → full refund.
 */
async function refundPaymentHandler(request) {
  const auth = requireAdmin(request);
  const {paymentId, amountPaise, reason} = request.data || {};

  if (!paymentId || typeof paymentId !== "string") {
    throw new HttpsError("invalid-argument", "paymentId is required.");
  }

  const db = getFirestore();
  const ref = db.collection(PAYMENTS).doc(paymentId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Payment record not found.");
  }

  const payment = Object.assign({id: snap.id}, snap.data() || {});
  if (payment.status !== "paid" && payment.status !== "partially_refunded") {
    throw new HttpsError(
      "failed-precondition",
      `Only paid payments can be refunded (current status: ${payment.status}).`,
    );
  }
  const rpPaymentId = payment.razorpay && payment.razorpay.paymentId;
  if (!rpPaymentId) {
    throw new HttpsError(
      "failed-precondition",
      "This payment has no Razorpay payment id.",
    );
  }

  const refundAmount = Number.isFinite(Number(amountPaise)) &&
    Number(amountPaise) > 0
    ? Number(amountPaise)
    : Number(payment.amountPaise);

  const totalRefunded = (payment.refunds || []).reduce(
    (sum, r) => sum + (Number(r.amountPaise) || 0),
    0,
  );
  if (totalRefunded + refundAmount > Number(payment.amountPaise)) {
    throw new HttpsError(
      "failed-precondition",
      "Refund amount exceeds the remaining refundable amount.",
    );
  }

  const client = getRazorpayClient();
  let refund;
  try {
    refund = await client.payments.refund(rpPaymentId, {
      amount: refundAmount,
      notes: {
        reason: String(reason || "admin_refund"),
        paymentDocId: paymentId,
        actor: auth.uid,
      },
    });
  } catch (error) {
    console.error("Razorpay refund failed", error);
    throw new HttpsError(
      "internal",
      "Razorpay refused the refund. Please check the dashboard.",
    );
  }

  const newTotal = totalRefunded + refundAmount;
  const nextStatus = newTotal >= Number(payment.amountPaise)
    ? "refunded"
    : "partially_refunded";

  await ref.set({
    status: nextStatus,
    refundedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    refunds: FieldValue.arrayUnion({
      refundId: refund.id,
      amountPaise: refundAmount,
      reason: String(reason || ""),
      by: auth.uid,
      byEmail: (auth.token && auth.token.email) || null,
      at: new Date().toISOString(),
    }),
  }, {merge: true});

  // Reverse side-effect on *full* refund only.
  if (nextStatus === "refunded") {
    try {
      await reversePaymentSideEffect(db, payment);
    } catch (error) {
      console.error(
        "Reverse side-effect failed for payment",
        paymentId,
        error,
      );
    }
  }

  await writeAuditLog({
    action: "payment.refund",
    actorUid: auth.uid,
    actorEmail: (auth.token && auth.token.email) || null,
    entityType: "payment",
    entityId: paymentId,
    metadata: {
      refundId: refund.id,
      amountPaise: refundAmount,
      reason: reason || "",
      resultingStatus: nextStatus,
    },
  });

  return {status: nextStatus, refundId: refund.id, amountPaise: refundAmount};
}

function sanitizeMetadata(input) {
  if (!input || typeof input !== "object") return {};
  const out = {};
  for (const key of Object.keys(input)) {
    const value = input[key];
    if (value === null || value === undefined) continue;
    out[String(key)] = String(value);
  }
  return out;
}

module.exports = {
  createPaymentOrderHandler,
  verifyPaymentSignatureHandler,
  refundPaymentHandler,
};
