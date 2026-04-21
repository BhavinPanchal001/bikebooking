const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");

initializeApp();

const db = getFirestore();

// ── Payments (Razorpay) ─────────────────────────────────────────────────────
const {
  createPaymentOrderHandler,
  verifyPaymentSignatureHandler,
  refundPaymentHandler,
} = require("./src/payments");
const {razorpayWebhookHandler} = require("./src/webhook");
const {clearExpiredBoostsHandler} = require("./src/scheduled");
const {setAdminClaimHandler} = require("./src/admin");

// Razorpay + bootstrap credentials are read directly from process.env so
// they can be supplied via `functions/.env.<projectId>` at deploy time
// instead of Secret Manager. See functions/.env.example for the required
// keys. For production deployments we recommend migrating these to
// Secret Manager by re-adding the `secrets: [...]` option on each export.

exports.createPaymentOrder = onCall(createPaymentOrderHandler);

exports.verifyPaymentSignature = onCall(verifyPaymentSignatureHandler);

exports.refundPayment = onCall(refundPaymentHandler);

exports.razorpayWebhook = onRequest(razorpayWebhookHandler);

exports.clearExpiredBoosts = onSchedule(
  {schedule: "every 15 minutes", timeZone: "Asia/Kolkata"},
  clearExpiredBoostsHandler,
);

exports.setAdminClaim = onCall(setAdminClaimHandler);

exports.sendQueuedNotification = onDocumentCreated(
  "notification_queue/{requestId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const request = snapshot.data() || {};
    const recipientId = normalizeString(request.recipientId);
    if (!recipientId) {
      await markQueue(snapshot.ref, {
        status: "skipped",
        reason: "missing_recipient",
      });
      return;
    }

    const userRef = db.collection("users").doc(recipientId);
    const userSnapshot = await userRef.get();
    const userData = userSnapshot.data() || {};
    const tokens = normalizeTokens(userData.fcmTokens);

    if (!tokens.length) {
      await markQueue(snapshot.ref, {
        status: "skipped",
        reason: "missing_tokens",
      });
      return;
    }

    const permissionStatus = normalizeString(userData.notificationPermissionStatus);
    const notificationsEnabled = userData.notificationsEnabled !== false;
    const preferences = normalizePreferences(userData.notificationPreferences);
    const type = normalizeString(request.type) || "system";

    if (!notificationsEnabled) {
      await markQueue(snapshot.ref, {
        status: "skipped",
        reason: "notifications_disabled",
      });
      return;
    }

    if (permissionStatus &&
        permissionStatus !== "authorized" &&
        permissionStatus !== "provisional") {
      await markQueue(snapshot.ref, {
        status: "skipped",
        reason: "permission_blocked",
      });
      return;
    }

    if (!isTypeEnabled(type, preferences)) {
      await markQueue(snapshot.ref, {
        status: "skipped",
        reason: "type_disabled",
      });
      return;
    }

    const title = normalizeString(request.title) || "Notification";
    const body = normalizeString(request.body) || "You have a new update.";
    const payload = buildDataPayload(request);

    try {
      const response = await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title,
          body,
        },
        data: payload,
        android: {
          priority: "high",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      const invalidTokens = [];
      response.responses.forEach((result, index) => {
        if (result.success) {
          return;
        }

        const code = result.error?.code || "";
        if (code.includes("registration-token-not-registered") ||
            code.includes("invalid-argument")) {
          invalidTokens.push(tokens[index]);
        }
      });

      if (invalidTokens.length) {
        await userRef.set({
          fcmTokens: FieldValue.arrayRemove(...invalidTokens),
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }

      const queueStatus = response.successCount === 0
        ? "failed"
        : response.failureCount > 0
          ? "partial"
          : "sent";

      await markQueue(snapshot.ref, {
        status: queueStatus,
        successCount: response.successCount,
        failureCount: response.failureCount,
        lastError: response.failureCount
          ? response.responses.find((item) => !item.success)?.error?.message || null
          : null,
      });
    } catch (error) {
      await markQueue(snapshot.ref, {
        status: "failed",
        reason: "send_error",
        lastError: error instanceof Error ? error.message : String(error),
      });
    }
  },
);

function normalizeString(value) {
  return String(value || "").trim();
}

function normalizeTokens(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((token) => normalizeString(token))
    .filter(Boolean);
}

function normalizePreferences(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }

  return value;
}

function readBool(map, key, fallback) {
  const value = map[key];
  if (typeof value === "boolean") {
    return value;
  }
  if (typeof value === "number") {
    return value !== 0;
  }
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (normalized === "true") {
      return true;
    }
    if (normalized === "false") {
      return false;
    }
  }
  return fallback;
}

function isTypeEnabled(type, preferences) {
  const allNotifications = readBool(preferences, "allNotifications", true);
  if (!allNotifications) {
    return false;
  }

  switch (normalizeString(type).toLowerCase()) {
    case "message":
      return readBool(preferences, "newMessage", true);
    case "listing":
    case "listing_update":
      return readBool(preferences, "adListing", true);
    case "product_view":
      return readBool(preferences, "viewedAd", true);
    case "listing_expiring":
    case "expiring_soon":
      return readBool(preferences, "expiringSoon", true);
    case "payment_failed":
      return readBool(preferences, "paymentFailed", true);
    case "subscription":
    case "subscription_expiring":
    case "subscription_reminder":
      return readBool(preferences, "subscriptionReminder", false);
    default:
      return allNotifications;
  }
}

function buildDataPayload(request) {
  return {
    notificationId: normalizeString(request.notificationId),
    recipientId: normalizeString(request.recipientId),
    title: normalizeString(request.title),
    body: normalizeString(request.body),
    type: normalizeString(request.type) || "system",
    senderId: normalizeString(request.senderId),
    senderName: normalizeString(request.senderName),
    senderPhotoUrl: normalizeString(request.senderPhotoUrl),
    targetRoute: normalizeString(request.targetRoute),
    productId: normalizeString(request.productId),
    chatId: normalizeString(request.chatId),
  };
}

async function markQueue(ref, patch) {
  await ref.set({
    ...patch,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}
