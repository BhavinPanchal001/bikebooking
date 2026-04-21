const {FieldValue, Timestamp, getFirestore} =
  require("firebase-admin/firestore");

/**
 * Applies the domain-level effect of a verified payment.
 *
 * Called from `verifyPaymentSignature` and, defensively, from the webhook
 * handler when a `payment.captured` event arrives. Implementations must be
 * idempotent: the same (paymentId, feeSlug) may be processed more than once.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {object} payment  hydrated `/payments/{id}` document
 * @return {Promise<void>}
 */
async function applyPaymentSideEffect(db, payment) {
  const kind = String(payment.kind || "");
  switch (kind) {
    case "boost":
      await applyBoostEffect(db, payment);
      return;
    case "listing_fee":
      await applyListingFeeEffect(db, payment);
      return;
    default:
      console.warn("applyPaymentSideEffect: unknown kind", kind);
  }
}

async function applyBoostEffect(db, payment) {
  const productId = payment.target && payment.target.id;
  if (!productId) {
    console.warn("applyBoostEffect: missing target.id", payment.id);
    return;
  }

  const durationDays = Number(
    (payment.metadata && payment.metadata.durationDays) ||
      payment.durationDays ||
      0,
  );
  if (!Number.isFinite(durationDays) || durationDays <= 0) {
    console.warn("applyBoostEffect: invalid durationDays", payment.id);
    return;
  }

  const now = new Date();
  const expires = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

  await db.collection("products").doc(productId).set(
    {
      isBoosted: true,
      boostPlanId: (payment.metadata && payment.metadata.feeSlug) || null,
      boostStartedAt: Timestamp.fromDate(now),
      boostExpiresAt: Timestamp.fromDate(expires),
      boostPaymentId: payment.razorpay && payment.razorpay.paymentId,
      boostPaymentDocId: payment.id,
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function applyListingFeeEffect(db, payment) {
  const productId = payment.target && payment.target.id;
  if (!productId) {
    console.warn("applyListingFeeEffect: missing target.id", payment.id);
    return;
  }

  await db.collection("products").doc(productId).set(
    {
      listingFeePaid: true,
      listingFeePaidAt: FieldValue.serverTimestamp(),
      listingFeePaymentId: payment.razorpay && payment.razorpay.paymentId,
      listingFeePaymentDocId: payment.id,
      // Products that were awaiting payment auto-activate on success.
      status: "active",
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

/**
 * Reverses the side-effect of a payment when a refund is issued.
 *
 * For boost: clears `isBoosted` fields.
 * For listing_fee: clears `listingFeePaid` and puts the product back into
 * `awaiting_payment` so the seller must pay again before it is live.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {object} payment
 * @return {Promise<void>}
 */
async function reversePaymentSideEffect(db, payment) {
  const kind = String(payment.kind || "");
  const productId = payment.target && payment.target.id;
  if (!productId) return;

  if (kind === "boost") {
    await db.collection("products").doc(productId).set(
      {
        isBoosted: false,
        boostPlanId: FieldValue.delete(),
        boostStartedAt: FieldValue.delete(),
        boostExpiresAt: FieldValue.delete(),
        boostPaymentId: FieldValue.delete(),
        boostPaymentDocId: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    return;
  }

  if (kind === "listing_fee") {
    await db.collection("products").doc(productId).set(
      {
        listingFeePaid: false,
        listingFeeRefundedAt: FieldValue.serverTimestamp(),
        status: "awaiting_payment",
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  }
}

module.exports = {applyPaymentSideEffect, reversePaymentSideEffect};
