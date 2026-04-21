const {FieldValue, getFirestore} = require("firebase-admin/firestore");

/**
 * Append-only audit log entry. Every admin-initiated write should call this.
 *
 * Intentionally tolerant: never throws to the caller (logging a best-effort
 * side-channel shouldn't break the primary operation). Failures are logged.
 *
 * @param {object} entry
 * @param {string} entry.action    e.g. "payment.refund", "listing.approve"
 * @param {string} [entry.actorUid]
 * @param {string} [entry.actorEmail]
 * @param {string} [entry.entityType]
 * @param {string} [entry.entityId]
 * @param {object} [entry.before]
 * @param {object} [entry.after]
 * @param {object} [entry.metadata]
 * @return {Promise<void>}
 */
async function writeAuditLog(entry) {
  try {
    const db = getFirestore();
    await db.collection("audit_logs").add({
      action: String(entry.action || "unknown"),
      actorUid: entry.actorUid || null,
      actorEmail: entry.actorEmail || null,
      entityType: entry.entityType || null,
      entityId: entry.entityId || null,
      before: entry.before || null,
      after: entry.after || null,
      metadata: entry.metadata || null,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    // Best-effort. Surface in logs, do not block the operation.
    console.error("Failed to write audit log", {
      action: entry && entry.action,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

module.exports = {writeAuditLog};
