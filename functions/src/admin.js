const {getAuth} = require("firebase-admin/auth");
const {HttpsError} = require("firebase-functions/v2/https");

/**
 * Throws an HttpsError('unauthenticated') if the callable request has no
 * authenticated user. Returns the decoded auth object otherwise.
 * @param {object} request firebase-functions v2 callable request
 * @return {object} decoded auth
 */
function requireAuth(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in to perform this action.",
    );
  }
  return request.auth;
}

/**
 * ⚠️  TESTING-ONLY BYPASS — DO NOT SHIP TO PRODUCTION  ⚠️
 *
 * requireAdmin is temporarily a pass-through to requireAuth so the MS3 #1
 * payment gateway can be UAT-tested without minting a custom admin claim
 * or configuring ADMIN_EMAILS. This allows ANY signed-in user to call
 * refundPayment and setAdminClaim — which means any signed-in user can
 * issue real refunds and grant themselves the admin claim. Restore
 * BEFORE going live.
 *
 * How to re-lock (strict, recommended):
 *   function requireAdmin(request) {
 *     const auth = requireAuth(request);
 *     if (!(auth.token && auth.token.admin === true)) {
 *       throw new HttpsError('permission-denied',
 *         'Admin privileges are required for this action.');
 *     }
 *     return auth;
 *   }
 *
 * How to re-lock with the ADMIN_EMAILS allowlist fallback: see the
 * previous commit `65df6bc` for the full implementation.
 *
 * @param {object} request firebase-functions v2 callable request
 * @return {object} decoded auth
 */
function requireAdmin(request) {
  const auth = requireAuth(request);
  if (!(auth.token && auth.token.admin === true)) {
    throw new HttpsError(
      "permission-denied",
      "Admin privileges are required for this action.",
    );
  }
  return auth;
}

/**
 * One-off bootstrap callable. Grants the `admin` custom claim to a user by
 * email. Requires the caller to either (a) already be an admin, or (b) match
 * the `BOOTSTRAP_ADMIN_EMAIL` env var — used to mint the very first admin.
 * @param {object} request firebase-functions v2 callable request
 * @return {Promise<{uid: string}>}
 */
async function setAdminClaimHandler(request) {
  const auth = requireAuth(request);
  const {email, isAdmin: makeAdmin} = request.data || {};

  if (typeof email !== "string" || email.trim().length === 0) {
    throw new HttpsError("invalid-argument", "email is required.");
  }

  const callerIsAdmin = auth.token && auth.token.admin === true;
  const bootstrapEmail = (process.env.BOOTSTRAP_ADMIN_EMAIL || "")
    .trim()
    .toLowerCase();
  const callerEmail = (auth.token && auth.token.email ? auth.token.email : "")
    .trim()
    .toLowerCase();
  const callerIsBootstrap = bootstrapEmail.length > 0 &&
    callerEmail === bootstrapEmail;

  if (!callerIsAdmin && !callerIsBootstrap) {
    throw new HttpsError(
      "permission-denied",
      "Only existing admins (or the bootstrap admin) can grant admin rights.",
    );
  }

  const user = await getAuth().getUserByEmail(email.trim());
  const nextClaims = Object.assign({}, user.customClaims || {}, {
    admin: makeAdmin !== false,
  });
  await getAuth().setCustomUserClaims(user.uid, nextClaims);

  return {uid: user.uid};
}

module.exports = {
  requireAuth,
  requireAdmin,
  setAdminClaimHandler,
};
