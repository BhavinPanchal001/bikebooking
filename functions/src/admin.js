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
 * Throws an HttpsError('permission-denied') if the caller is not an admin.
 * Admin status is determined by the custom claim `admin === true`.
 * @param {object} request firebase-functions v2 callable request
 * @return {object} decoded auth
 */
function requireAdmin(request) {
  const auth = requireAuth(request);
  const isAdmin = auth.token && auth.token.admin === true;
  if (!isAdmin) {
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
