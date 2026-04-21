const crypto = require("crypto");
const Razorpay = require("razorpay");
const {HttpsError} = require("firebase-functions/v2/https");

let cachedClient = null;

function getKeyId() {
  return (process.env.RAZORPAY_KEY_ID || "").trim();
}

function getKeySecret() {
  return (process.env.RAZORPAY_KEY_SECRET || "").trim();
}

function getWebhookSecret() {
  return (process.env.RAZORPAY_WEBHOOK_SECRET || "").trim();
}

/**
 * Returns a memoised Razorpay SDK client.
 * Throws `HttpsError('failed-precondition')` if keys are not configured.
 * @return {Razorpay}
 */
function getRazorpayClient() {
  if (cachedClient) {
    return cachedClient;
  }

  const keyId = getKeyId();
  const keySecret = getKeySecret();
  if (!keyId || !keySecret) {
    throw new HttpsError(
      "failed-precondition",
      "Razorpay credentials are not configured on the server.",
    );
  }

  cachedClient = new Razorpay({key_id: keyId, key_secret: keySecret});
  return cachedClient;
}

/**
 * Verifies the HMAC-SHA256 signature that Razorpay returns from its checkout.
 * Used by the verifyPaymentSignature callable after a successful checkout.
 *
 * @param {object} params
 * @param {string} params.orderId      razorpay_order_id
 * @param {string} params.paymentId    razorpay_payment_id
 * @param {string} params.signature    razorpay_signature
 * @return {boolean}
 */
function verifyCheckoutSignature({orderId, paymentId, signature}) {
  const secret = getKeySecret();
  if (!secret || !orderId || !paymentId || !signature) {
    return false;
  }
  const expected = crypto
    .createHmac("sha256", secret)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");
  return timingSafeEqualHex(expected, signature);
}

/**
 * Verifies the `X-Razorpay-Signature` header sent on webhook deliveries.
 *
 * @param {Buffer|string} rawBody   express raw body
 * @param {string} signatureHeader  `X-Razorpay-Signature` header value
 * @return {boolean}
 */
function verifyWebhookSignature(rawBody, signatureHeader) {
  const secret = getWebhookSecret();
  if (!secret || !signatureHeader) {
    return false;
  }
  const payload = Buffer.isBuffer(rawBody)
    ? rawBody
    : Buffer.from(String(rawBody || ""), "utf8");
  const expected = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("hex");
  return timingSafeEqualHex(expected, signatureHeader);
}

function timingSafeEqualHex(a, b) {
  try {
    const bufA = Buffer.from(String(a), "hex");
    const bufB = Buffer.from(String(b), "hex");
    if (bufA.length !== bufB.length) return false;
    return crypto.timingSafeEqual(bufA, bufB);
  } catch (error) {
    return false;
  }
}

module.exports = {
  getRazorpayClient,
  getKeyId,
  getKeySecret,
  getWebhookSecret,
  verifyCheckoutSignature,
  verifyWebhookSignature,
};
