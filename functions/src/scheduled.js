const {FieldValue, Timestamp, getFirestore} =
  require("firebase-admin/firestore");

/**
 * Scheduled job: clear expired boosts.
 *
 * The old client-side `removeExpiredBoost` only ran when a user happened to
 * open their listing. That meant expired boosts stayed `isBoosted: true` in
 * queries forever. This runs every 15 minutes and clears boosts whose
 * `boostExpiresAt` is in the past.
 *
 * @return {Promise<void>}
 */
async function clearExpiredBoostsHandler() {
  const db = getFirestore();
  const now = Timestamp.now();

  const snap = await db
    .collection("products")
    .where("isBoosted", "==", true)
    .where("boostExpiresAt", "<=", now)
    .limit(500)
    .get();

  if (snap.empty) {
    console.info("clearExpiredBoosts: nothing to do");
    return;
  }

  const writer = db.bulkWriter();
  for (const doc of snap.docs) {
    writer.set(doc.ref, {
      isBoosted: false,
      boostPlanId: FieldValue.delete(),
      boostStartedAt: FieldValue.delete(),
      boostExpiresAt: FieldValue.delete(),
      boostPaymentId: FieldValue.delete(),
      boostPaymentDocId: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  await writer.close();

  console.info(`clearExpiredBoosts: cleared ${snap.size} products`);
}

module.exports = {clearExpiredBoostsHandler};
