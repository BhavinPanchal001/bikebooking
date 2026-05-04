const {FieldValue, Timestamp, getFirestore} =
  require("firebase-admin/firestore");
const {HttpsError} = require("firebase-functions/v2/https");

const {requireAdmin} = require("./admin");
const {writeAuditLog} = require("./audit");

const MS_PER_DAY = 24 * 60 * 60 * 1000;
const MAX_DURATION_DAYS = 365;

function toPositiveInteger(value, fieldName) {
  const num = Number(value);
  if (!Number.isFinite(num) || !Number.isInteger(num) || num <= 0) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} must be a positive integer.`,
    );
  }
  if (num > MAX_DURATION_DAYS) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} may not exceed ${MAX_DURATION_DAYS} days.`,
    );
  }
  return num;
}

function toTrimmedString(value) {
  return typeof value === "string" ? value.trim() : "";
}

async function loadProduct(productId) {
  if (typeof productId !== "string" || !productId.trim()) {
    throw new HttpsError("invalid-argument", "productId is required.");
  }
  const ref = getFirestore().collection("products").doc(productId.trim());
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Product not found.");
  }
  return {ref, data: snap.data() || {}};
}

function extractExistingExpiry(data) {
  const raw = data && data.boostExpiresAt;
  if (!raw) return null;
  if (typeof raw.toDate === "function") return raw.toDate();
  if (raw instanceof Date) return raw;
  return null;
}

function rethrowCallableError(error, context) {
  if (error instanceof HttpsError) {
    throw error;
  }

  const message = error instanceof Error ? error.message : String(error);
  console.error(`${context} failed`, {
    error: message,
    stack: error instanceof Error ? error.stack : undefined,
  });
  throw new HttpsError(
    "internal",
    `${context} failed: ${message}`,
  );
}

/**
 * Callable: adminGrantBoost
 *
 * Grants a free (admin-originated) boost to a product. Decoupled from
 * Razorpay — there is no `/payments` record and the server flips the
 * boost fields directly via the admin SDK. Use this to comp a seller,
 * run campaigns, or seed the marketplace.
 *
 * Input: { productId, durationDays, planSlug?, note? }
 * Output: { productId, boostExpiresAt: ISO string }
 */
async function adminGrantBoostHandler(request) {
  const auth = requireAdmin(request);
  const {productId, durationDays, planSlug, note} = request.data || {};

  const days = toPositiveInteger(durationDays, "durationDays");
  const {ref, data} = await loadProduct(productId);

  const now = new Date();
  const expires = new Date(now.getTime() + days * MS_PER_DAY);
  const slug = toTrimmedString(planSlug) || "admin_grant";

  await ref.set(
    {
      isBoosted: true,
      boostPlanId: slug,
      boostStartedAt: Timestamp.fromDate(now),
      boostExpiresAt: Timestamp.fromDate(expires),
      boostGrantSource: "admin",
      boostGrantedBy: auth.uid,
      boostGrantedByEmail: (auth.token && auth.token.email) || null,
      boostGrantNote: toTrimmedString(note) || null,
      // Admin-granted boosts intentionally leave payment fields null so the
      // payments page doesn't surface them as "paid".
      boostPaymentId: null,
      boostPaymentDocId: null,
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  await writeAuditLog({
    action: "boost.grant",
    actorUid: auth.uid,
    actorEmail: (auth.token && auth.token.email) || null,
    entityType: "product",
    entityId: ref.id,
    before: {
      isBoosted: data.isBoosted === true,
      boostExpiresAt: extractExistingExpiry(data),
    },
    after: {isBoosted: true, boostExpiresAt: expires.toISOString()},
    metadata: {durationDays: days, planSlug: slug, note: toTrimmedString(note)},
  });

  return {productId: ref.id, boostExpiresAt: expires.toISOString()};
}

/**
 * Callable: adminExtendBoost
 *
 * Pushes `boostExpiresAt` forward by `additionalDays`. If the boost has
 * already expired (or was cleared) the new expiry is computed from now.
 *
 * Input: { productId, additionalDays, note? }
 * Output: { productId, boostExpiresAt: ISO string }
 */
async function adminExtendBoostHandler(request) {
  const auth = requireAdmin(request);
  const {productId, additionalDays, note} = request.data || {};

  const days = toPositiveInteger(additionalDays, "additionalDays");
  const {ref, data} = await loadProduct(productId);

  const now = new Date();
  const currentExpiry = extractExistingExpiry(data);
  const base = currentExpiry && currentExpiry.getTime() > now.getTime()
    ? currentExpiry
    : now;
  const expires = new Date(base.getTime() + days * MS_PER_DAY);

  await ref.set(
    {
      isBoosted: true,
      boostStartedAt: data.boostStartedAt || Timestamp.fromDate(now),
      boostExpiresAt: Timestamp.fromDate(expires),
      boostPlanId: data.boostPlanId || "admin_grant",
      // Preserve the original source. Paid boosts never set
      // `boostGrantSource`, so falling back to `"admin"` here would
      // incorrectly relabel a Razorpay-paid boost as an admin grant in
      // the admin UI and summary counts.
      boostGrantSource: data.boostGrantSource || null,
      boostLastExtendedBy: auth.uid,
      boostLastExtendedByEmail: (auth.token && auth.token.email) || null,
      boostLastExtendedAt: FieldValue.serverTimestamp(),
      boostLastExtensionDays: days,
      boostLastExtensionNote: toTrimmedString(note) || null,
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  await writeAuditLog({
    action: "boost.extend",
    actorUid: auth.uid,
    actorEmail: (auth.token && auth.token.email) || null,
    entityType: "product",
    entityId: ref.id,
    before: {boostExpiresAt: currentExpiry ? currentExpiry.toISOString() : null},
    after: {boostExpiresAt: expires.toISOString()},
    metadata: {additionalDays: days, note: toTrimmedString(note)},
  });

  return {productId: ref.id, boostExpiresAt: expires.toISOString()};
}

/**
 * Callable: adminRevokeBoost
 *
 * Clears the boost fields on a product (no refund — refunds are handled
 * by the refundPayment callable).
 *
 * Input: { productId, note? }
 * Output: { productId }
 */
async function adminRevokeBoostHandler(request) {
  const auth = requireAdmin(request);
  const {productId, note} = request.data || {};

  const {ref, data} = await loadProduct(productId);

  await ref.set(
    {
      isBoosted: false,
      boostPlanId: FieldValue.delete(),
      boostStartedAt: FieldValue.delete(),
      boostExpiresAt: FieldValue.delete(),
      boostPaymentId: FieldValue.delete(),
      boostPaymentDocId: FieldValue.delete(),
      boostGrantSource: FieldValue.delete(),
      boostGrantedBy: FieldValue.delete(),
      boostGrantedByEmail: FieldValue.delete(),
      boostGrantNote: FieldValue.delete(),
      boostRevokedAt: FieldValue.serverTimestamp(),
      boostRevokedBy: auth.uid,
      boostRevokedByEmail: (auth.token && auth.token.email) || null,
      boostRevokeNote: toTrimmedString(note) || null,
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  await writeAuditLog({
    action: "boost.revoke",
    actorUid: auth.uid,
    actorEmail: (auth.token && auth.token.email) || null,
    entityType: "product",
    entityId: ref.id,
    before: {
      isBoosted: data.isBoosted === true,
      boostExpiresAt: extractExistingExpiry(data),
    },
    after: {isBoosted: false},
    metadata: {note: toTrimmedString(note)},
  });

  return {productId: ref.id};
}

/**
 * Callable: adminSetEditorialFeatured
 *
 * Editorial "featured" flag. Separate from paid boost so operators can
 * hand-pick listings for the home banner without touching the paid tier.
 *
 * Input: { productId, isFeatured, note? }
 * Output: { productId, isEditorialFeatured }
 */
async function adminSetEditorialFeaturedHandler(request) {
  try {
    const auth = requireAdmin(request);
    const {productId, isFeatured, note} = request.data || {};

    const {ref, data} = await loadProduct(productId);
    const shouldFeature = isFeatured === true;

    const update = shouldFeature
      ? {
        isEditorialFeatured: true,
        editorialFeaturedAt: FieldValue.serverTimestamp(),
        editorialFeaturedBy: auth.uid,
        editorialFeaturedByEmail: (auth.token && auth.token.email) || null,
        editorialFeaturedNote: toTrimmedString(note) || null,
        updatedAt: FieldValue.serverTimestamp(),
      }
      : {
        isEditorialFeatured: false,
        editorialFeaturedAt: FieldValue.delete(),
        editorialFeaturedBy: FieldValue.delete(),
        editorialFeaturedByEmail: FieldValue.delete(),
        editorialFeaturedNote: FieldValue.delete(),
        editorialUnfeaturedAt: FieldValue.serverTimestamp(),
        editorialUnfeaturedBy: auth.uid,
        editorialUnfeaturedByEmail: (auth.token && auth.token.email) || null,
        editorialUnfeaturedNote: toTrimmedString(note) || null,
        updatedAt: FieldValue.serverTimestamp(),
      };

    await ref.set(update, {merge: true});

    await writeAuditLog({
      action: shouldFeature ? "feature.add" : "feature.remove",
      actorUid: auth.uid,
      actorEmail: (auth.token && auth.token.email) || null,
      entityType: "product",
      entityId: ref.id,
      before: {isEditorialFeatured: data.isEditorialFeatured === true},
      after: {isEditorialFeatured: shouldFeature},
      metadata: {note: toTrimmedString(note)},
    });

    return {productId: ref.id, isEditorialFeatured: shouldFeature};
  } catch (error) {
    rethrowCallableError(error, "Editorial featured update");
  }
}

module.exports = {
  adminGrantBoostHandler,
  adminExtendBoostHandler,
  adminRevokeBoostHandler,
  adminSetEditorialFeaturedHandler,
};
