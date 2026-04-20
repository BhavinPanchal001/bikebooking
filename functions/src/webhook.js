const {FieldValue, getFirestore} = require("firebase-admin/firestore");

const {writeAuditLog} = require("./audit");
const {verifyWebhookSignature} = require("./razorpay");
const {
  applyPaymentSideEffect,
  reversePaymentSideEffect,
} = require("./sideEffects");

const PAYMENTS = "payments";
const EVENTS = "razorpay_webhook_events";

/**
 * HTTPS handler for Razorpay webhook deliveries.
 *
 * Verifies the X-Razorpay-Signature, then dispatches on `event`:
 *   - payment.captured → mark paid + apply side-effect (idempotent)
 *   - payment.failed   → mark failed
 *   - refund.created   → record in /payments/{}.refunds
 *   - refund.processed → finalise refund status
 *
 * Uses a /razorpay_webhook_events/{eventId} doc as an idempotency ledger so
 * Razorpay can safely replay deliveries.
 *
 * @param {object} req express-like request from functions v2 onRequest
 * @param {object} res express-like response
 */
async function razorpayWebhookHandler(req, res) {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  const signature = req.get
    ? req.get("x-razorpay-signature")
    : (req.headers && req.headers["x-razorpay-signature"]);

  const rawBody = req.rawBody;
  const ok = verifyWebhookSignature(rawBody, signature);
  if (!ok) {
    res.status(401).send("Invalid signature");
    return;
  }

  let payload;
  try {
    payload = typeof req.body === "object" && req.body !== null
      ? req.body
      : JSON.parse(Buffer.isBuffer(rawBody)
        ? rawBody.toString("utf8")
        : String(rawBody || "{}"));
  } catch (error) {
    res.status(400).send("Invalid JSON");
    return;
  }

  const eventId = String(
    (payload && payload.id) ||
      (req.get && req.get("x-razorpay-event-id")) ||
      "",
  ).trim();
  const eventType = String(payload && payload.event || "");

  if (!eventId || !eventType) {
    res.status(400).send("Missing event id or type");
    return;
  }

  const db = getFirestore();
  const eventRef = db.collection(EVENTS).doc(eventId);

  // Idempotency: if we've processed this id before, ack quickly.
  const existing = await eventRef.get();
  if (existing.exists && existing.data() && existing.data().processed) {
    res.status(200).send("Already processed");
    return;
  }

  await eventRef.set({
    eventId,
    type: eventType,
    receivedAt: FieldValue.serverTimestamp(),
    processed: false,
  }, {merge: true});

  try {
    await dispatchWebhook(db, eventType, payload);
    await eventRef.set({
      processed: true,
      processedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    res.status(200).send("ok");
  } catch (error) {
    console.error("Webhook processing failed", eventType, error);
    await eventRef.set({
      processed: false,
      lastError: error instanceof Error ? error.message : String(error),
      lastAttemptedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    // 5xx so Razorpay retries.
    res.status(500).send("Processing error");
  }
}

async function dispatchWebhook(db, eventType, payload) {
  const entity = (payload && payload.payload) || {};
  switch (eventType) {
    case "payment.captured":
      await onPaymentCaptured(db, entity);
      return;
    case "payment.failed":
      await onPaymentFailed(db, entity);
      return;
    case "refund.created":
    case "refund.processed":
      await onRefundEvent(db, eventType, entity);
      return;
    default:
      // Unknown/ignored event: still mark processed to avoid retries.
      console.info("Ignoring Razorpay webhook event", eventType);
  }
}

async function onPaymentCaptured(db, entity) {
  const rp = entity.payment && entity.payment.entity;
  if (!rp) return;

  const paymentDocId = findPaymentDocId(rp);
  if (!paymentDocId) {
    console.warn("payment.captured with no paymentDocId note", rp.id);
    return;
  }
  const ref = db.collection(PAYMENTS).doc(paymentDocId);
  const snap = await ref.get();
  if (!snap.exists) {
    console.warn("payment.captured for unknown doc", paymentDocId);
    return;
  }
  const payment = Object.assign({id: snap.id}, snap.data() || {});

  // Already paid? Just append event id for traceability.
  if (payment.status === "paid" || payment.status === "refunded" ||
      payment.status === "partially_refunded") {
    await ref.set({
      webhookEventIds: FieldValue.arrayUnion(rp.id),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return;
  }

  const updated = {
    status: "paid",
    paidAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    razorpay: Object.assign({}, payment.razorpay || {}, {
      paymentId: rp.id,
      method: rp.method || null,
      errorCode: null,
      errorDescription: null,
    }),
    webhookEventIds: FieldValue.arrayUnion(rp.id),
  };
  await ref.set(updated, {merge: true});

  const hydrated = Object.assign({}, payment, updated);
  await applyPaymentSideEffect(db, hydrated);

  await writeAuditLog({
    action: "payment.webhook_captured",
    entityType: "payment",
    entityId: paymentDocId,
    metadata: {razorpayPaymentId: rp.id},
  });
}

async function onPaymentFailed(db, entity) {
  const rp = entity.payment && entity.payment.entity;
  if (!rp) return;
  const paymentDocId = findPaymentDocId(rp);
  if (!paymentDocId) return;

  const ref = db.collection(PAYMENTS).doc(paymentDocId);
  const snap = await ref.get();
  if (!snap.exists) return;
  const payment = Object.assign({id: snap.id}, snap.data() || {});

  // Do not overwrite a terminal success status — a stale `payment.failed`
  // replay must not clobber a payment we already verified as `paid`
  // (or refunded / partially_refunded).
  if (payment.status === "paid" || payment.status === "refunded" ||
      payment.status === "partially_refunded") {
    await ref.set({
      webhookEventIds: FieldValue.arrayUnion(rp.id || "failed"),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return;
  }

  await ref.set({
    status: "failed",
    failedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    razorpay: Object.assign({}, payment.razorpay || {}, {
      paymentId: rp.id || null,
      errorCode: rp.error_code || null,
      errorDescription: rp.error_description || null,
    }),
    webhookEventIds: FieldValue.arrayUnion(rp.id || "failed"),
  }, {merge: true});

  await writeAuditLog({
    action: "payment.webhook_failed",
    entityType: "payment",
    entityId: paymentDocId,
    metadata: {
      razorpayPaymentId: rp.id || null,
      errorCode: rp.error_code || null,
    },
  });
}

async function onRefundEvent(db, eventType, entity) {
  const rp = entity.refund && entity.refund.entity;
  if (!rp) return;

  // Refund notes carry our paymentDocId (we set it when we call refund).
  const paymentDocId = (rp.notes && rp.notes.paymentDocId) || null;
  if (!paymentDocId) {
    console.warn("refund event with no paymentDocId note", rp.id);
    return;
  }

  const ref = db.collection(PAYMENTS).doc(paymentDocId);
  const processed = eventType === "refund.processed";

  // Read-modify-write of the `refunds` array must be atomic: two
  // concurrent refund webhooks for the same payment would otherwise
  // both read the same base array, each append only their own entry,
  // and clobber each other with `set({refunds}, {merge: true})`.
  // Wrapping in a transaction forces Firestore to retry one of them
  // against the fresh state.
  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const payment = Object.assign({id: snap.id}, snap.data() || {});

    // Upsert refund entry by refund id.
    const existing = (payment.refunds || []).find(
      (r) => r.refundId === rp.id,
    );
    const nextRefunds = existing
      ? (payment.refunds || []).map((r) => r.refundId === rp.id
        ? Object.assign({}, r, {
          amountPaise: Number(rp.amount) || r.amountPaise,
          status: rp.status || r.status || null,
        })
        : r)
      : (payment.refunds || []).concat([{
        refundId: rp.id,
        amountPaise: Number(rp.amount) || 0,
        status: rp.status || null,
        reason: (rp.notes && rp.notes.reason) || "",
        at: new Date().toISOString(),
      }]);

    const total = nextRefunds.reduce(
      (sum, r) => sum + (Number(r.amountPaise) || 0),
      0,
    );
    const nextStatus = processed
      ? (total >= Number(payment.amountPaise)
        ? "refunded"
        : "partially_refunded")
      : payment.status;

    tx.set(ref, {
      refunds: nextRefunds,
      status: nextStatus,
      refundedAt: processed ? FieldValue.serverTimestamp() : payment.refundedAt,
      updatedAt: FieldValue.serverTimestamp(),
      webhookEventIds: FieldValue.arrayUnion(rp.id),
    }, {merge: true});

    return {payment, nextStatus};
  });

  if (!result) return;

  if (processed && result.nextStatus === "refunded") {
    try {
      await reversePaymentSideEffect(db, result.payment);
    } catch (error) {
      console.error("Webhook reverse side-effect failed", paymentDocId, error);
    }
  }

  await writeAuditLog({
    action: `payment.webhook_${eventType}`,
    entityType: "payment",
    entityId: paymentDocId,
    metadata: {refundId: rp.id, amountPaise: rp.amount},
  });
}

function findPaymentDocId(rp) {
  return (rp && rp.notes && (rp.notes.paymentDocId || rp.notes.payment_doc_id))
    || null;
}

module.exports = {razorpayWebhookHandler};
