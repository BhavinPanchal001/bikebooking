const {getFirestore} = require("firebase-admin/firestore");
const {HttpsError} = require("firebase-functions/v2/https");

/**
 * Known fee kinds. The admin panel master collection is keyed by a slug and
 * declares its own `kind`, but the side-effect dispatcher only handles these.
 */
const KNOWN_KINDS = new Set(["boost", "listing_fee"]);

/**
 * Fetches a fee config doc from `/fee_config/{slug}` and validates it.
 * @param {string} slug
 * @return {Promise<object>}
 */
async function loadFeeConfig(slug) {
  if (typeof slug !== "string" || !slug.trim()) {
    throw new HttpsError("invalid-argument", "feeSlug is required.");
  }

  const ref = getFirestore().collection("fee_config").doc(slug.trim());
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError(
      "not-found",
      `Fee config '${slug}' does not exist.`,
    );
  }

  const data = snap.data() || {};
  if (data.isActive === false) {
    throw new HttpsError(
      "failed-precondition",
      `Fee '${slug}' is currently disabled.`,
    );
  }

  const kind = String(data.kind || "").trim();
  const amountPaise = Number(data.amountPaise);
  if (!KNOWN_KINDS.has(kind)) {
    throw new HttpsError(
      "failed-precondition",
      `Fee '${slug}' has an unsupported kind '${kind}'.`,
    );
  }
  if (!Number.isInteger(amountPaise) || amountPaise <= 0) {
    throw new HttpsError(
      "failed-precondition",
      `Fee '${slug}' has an invalid amountPaise.`,
    );
  }

  return {
    slug,
    kind,
    amountPaise,
    displayName: String(data.displayName || slug),
    durationDays: Number.isFinite(data.durationDays) && data.durationDays > 0
      ? Number(data.durationDays)
      : null,
    currency: String(data.currency || "INR"),
  };
}

module.exports = {loadFeeConfig, KNOWN_KINDS};
