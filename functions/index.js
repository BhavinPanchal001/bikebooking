const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {
  FieldValue,
  getFirestore,
} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {HttpsError, onCall, onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
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
const {
  adminGrantBoostHandler,
  adminExtendBoostHandler,
  adminRevokeBoostHandler,
  adminSetEditorialFeaturedHandler,
} = require("./src/adminBoost");

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

exports.adminGrantBoost = onCall(adminGrantBoostHandler);
exports.adminExtendBoost = onCall(adminExtendBoostHandler);
exports.adminRevokeBoost = onCall(adminRevokeBoostHandler);
exports.adminSetEditorialFeatured = onCall(adminSetEditorialFeaturedHandler);

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

async function syncAuthDisabledState(userId, disabled) {
  try {
    await getAuth().updateUser(userId, {disabled});
    return disabled ? "disabled" : "enabled";
  } catch (error) {
    const code = String(error?.code || "").trim().toLowerCase();
    if (code === "auth/user-not-found" || code === "user-not-found") {
      return "auth_user_not_found";
    }

    console.error(
      `Unable to ${disabled ? "disable" : "enable"} auth access for user ${userId}.`,
      error,
    );
    return "auth_sync_failed";
  }
}

exports.adminBlockUser = onCall(async (request) => {
  const actor = await requireAdmin(request);
  const userId = readRequiredString(request.data?.userId, "userId");
  const userRef = db.collection("users").doc(userId);
  const userSnapshot = await userRef.get();

  if (!userSnapshot.exists) {
    throw new HttpsError("not-found", "The selected user does not exist.");
  }

  const before = serializeValue(userSnapshot.data());
  const adminActor = actor.email || actor.uid;
  const authAccessState = await syncAuthDisabledState(userId, true);

  await userRef.set({
    adminBlocked: true,
    accountStatus: "blocked",
    adminBlockedAt: FieldValue.serverTimestamp(),
    adminBlockedBy: adminActor,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  await writeAuditLog({
    actor,
    action: "block_user",
    entity: "user",
    entityId: userId,
    before,
    after: {
      ...before,
      adminBlocked: true,
      accountStatus: "blocked",
      adminBlockedBy: adminActor,
      authAccessState,
    },
  });

  return {
    ok: true,
    userId,
    accountStatus: "blocked",
    authAccessState,
  };
});

exports.adminUnblockUser = onCall(async (request) => {
  const actor = await requireAdmin(request);
  const userId = readRequiredString(request.data?.userId, "userId");
  const userRef = db.collection("users").doc(userId);
  const userSnapshot = await userRef.get();

  if (!userSnapshot.exists) {
    throw new HttpsError("not-found", "The selected user does not exist.");
  }

  const before = serializeValue(userSnapshot.data());
  const authAccessState = await syncAuthDisabledState(userId, false);

  await userRef.set({
    adminBlocked: false,
    accountStatus: "active",
    adminBlockedAt: FieldValue.delete(),
    adminBlockedBy: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  await writeAuditLog({
    actor,
    action: "unblock_user",
    entity: "user",
    entityId: userId,
    before,
    after: {
      ...before,
      adminBlocked: false,
      accountStatus: "active",
      adminBlockedAt: null,
      adminBlockedBy: null,
      authAccessState,
    },
  });

  return {
    ok: true,
    userId,
    accountStatus: "active",
    authAccessState,
  };
});

exports.adminDeleteUser = onCall(async (request) => {
  const actor = await requireAdmin(request);
  const userId = readRequiredString(request.data?.userId, "userId");
  const result = await deleteUserCascade({userId, actor});

  let authDeleted = false;
  try {
    await getAuth().deleteUser(userId);
    authDeleted = true;
  } catch (error) {
    if (error.code !== "auth/user-not-found" && error.code !== "user-not-found") {
      console.error(`Failed to delete Firebase Auth user for ${userId}:`, error);
    }
  }

  return {
    ok: true,
    authDeleted,
    ...result,
  };
});

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

async function requireAdmin(request) {
  const uid = normalizeString(request.auth?.uid);
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in before using admin actions.");
  }

  if (request.auth?.token?.admin === true) {
    return {
      uid,
      email: normalizeString(request.auth.token.email),
      roleSource: "custom-claim",
    };
  }

  const adminSnapshot = await db.collection("admin_users").doc(uid).get();
  if (!adminSnapshot.exists) {
    throw new HttpsError(
      "permission-denied",
      "Only allowlisted admin accounts can manage users.",
    );
  }

  const adminData = adminSnapshot.data() || {};
  return {
    uid,
    email: normalizeString(request.auth?.token?.email || adminData.email),
    roleSource: "allowlist",
  };
}

function readRequiredString(value, fieldName) {
  const normalized = normalizeString(value);
  if (!normalized) {
    throw new HttpsError(
      "invalid-argument",
      `A valid ${fieldName} is required for this admin action.`,
    );
  }

  return normalized;
}

async function writeAuditLog({
  actor,
  action,
  entity,
  entityId,
  before,
  after,
  metadata,
}) {
  await db.collection("audit_logs").add({
    actorUid: actor.uid,
    actorEmail: actor.email || null,
    action,
    entity,
    entityId,
    before: serializeValue(before),
    after: serializeValue(after),
    metadata: serializeValue(metadata) || null,
    ts: FieldValue.serverTimestamp(),
  });
}

function serializeValue(value) {
  if (value === undefined) {
    return undefined;
  }

  if (value === null ||
      typeof value === "string" ||
      typeof value === "number" ||
      typeof value === "boolean") {
    return value;
  }

  if (Array.isArray(value)) {
    return value
      .map((entry) => serializeValue(entry))
      .filter((entry) => entry !== undefined);
  }

  if (typeof value?.toDate === "function") {
    try {
      return value.toDate().toISOString();
    } catch (error) {
      return null;
    }
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  if (typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value)
        .map(([key, entry]) => [key, serializeValue(entry)])
        .filter(([, entry]) => entry !== undefined),
    );
  }

  return String(value);
}

async function deleteUserCascade({userId, actor}) {
  const userRef = db.collection("users").doc(userId);
  const userSnapshot = await userRef.get();

  if (!userSnapshot.exists) {
    throw new HttpsError("not-found", "The selected user does not exist.");
  }

  const writer = db.bulkWriter();
  writer.onWriteError((error) => error.failedAttempts < 3);

  const cleanup = {
    deletedDocuments: 0,
    deletedListings: 0,
    deletedChats: 0,
    deletedReports: 0,
    deletedBlocks: 0,
    deletedBoostRecords: 0,
    deletedQueueNotifications: 0,
    cleanedLegacyBlocks: 0,
    deletedActiveBoosts: 0,
  };
  const queuedDeletes = new Set();
  const queuedUpdates = new Set();

  const productSnapshot = await db
    .collection("products")
    .where("sellerId", "==", userId)
    .get();
  const productIds = productSnapshot.docs.map((doc) => doc.id);
  cleanup.deletedListings = productSnapshot.docs.length;
  cleanup.deletedActiveBoosts = productSnapshot.docs.filter(
    (doc) => doc.data().isBoosted === true,
  ).length;

  await queueDocumentTreeDelete(userRef, {writer, queuedDeletes, cleanup});

  await queueQueryTreeDelete(
    db.collectionGroup("reviews").where("reviewerId", "==", userId),
    {writer, queuedDeletes, cleanup},
  );

  const reportQueries = [
    db.collection("seller_reports").where("reporterId", "==", userId),
    db.collection("seller_reports").where("sellerId", "==", userId),
    db.collection("seller_reports").where("userId", "==", userId),
    db.collection("seller_reports").where("reportedUserId", "==", userId),
    db.collection("seller_reports").where("reportedPersonId", "==", userId),
  ];

  for (const query of reportQueries) {
    cleanup.deletedReports += await queueQueryTreeDelete(
      query,
      {writer, queuedDeletes, cleanup},
    );
  }

  const blockQueries = [
    db.collection("user_blocks").where("blockerId", "==", userId),
    db.collection("user_blocks").where("blockedUserId", "==", userId),
  ];

  for (const query of blockQueries) {
    cleanup.deletedBlocks += await queueQueryTreeDelete(
      query,
      {writer, queuedDeletes, cleanup},
    );
  }

  const chatSnapshot = await db
    .collection("chats")
    .where("participants", "array-contains", userId)
    .get();
  cleanup.deletedChats = chatSnapshot.docs.length;
  for (const chatDoc of chatSnapshot.docs) {
    await queueDocumentTreeDelete(chatDoc.ref, {
      writer,
      queuedDeletes,
      cleanup,
    });
  }

  for (const productDoc of productSnapshot.docs) {
    await queueDocumentTreeDelete(productDoc.ref, {
      writer,
      queuedDeletes,
      cleanup,
    });
  }

  cleanup.deletedBoostRecords += await queueQueryTreeDelete(
    db.collection("boosts").where("sellerId", "==", userId),
    {writer, queuedDeletes, cleanup},
  );

  const queueQueries = [
    db.collection("notification_queue").where("recipientId", "==", userId),
    db.collection("notification_queue").where("senderId", "==", userId),
  ];
  for (const query of queueQueries) {
    cleanup.deletedQueueNotifications += await queueQueryTreeDelete(
      query,
      {writer, queuedDeletes, cleanup},
    );
  }

  const legacyBlockSnapshot = await db
    .collection("users")
    .where("blockedSellerIds", "array-contains", userId)
    .get();

  for (const doc of legacyBlockSnapshot.docs) {
    if (doc.id === userId || queuedUpdates.has(doc.ref.path)) {
      continue;
    }

    queuedUpdates.add(doc.ref.path);
    cleanup.cleanedLegacyBlocks += 1;
    writer.update(doc.ref, {
      blockedSellerIds: FieldValue.arrayRemove(userId),
      [`blockedSellersMeta.${userId}`]: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  if (productIds.length > 0) {
    for (const productId of productIds) {
      await queueCollectionGroupDocDeletes(
        "favorites",
        productId,
        {writer, queuedDeletes, cleanup},
      );
      await queueCollectionGroupDocDeletes(
        "recentlyViewed",
        productId,
        {writer, queuedDeletes, cleanup},
      );
    }
  }

  await writer.close();

  await writeAuditLog({
    actor,
    action: "delete_user",
    entity: "user",
    entityId: userId,
    before: userSnapshot.data(),
    after: {
      deleted: true,
      productIds,
      cleanup,
    },
    metadata: {
      productIds,
      cleanup,
    },
  });

  return {
    userId,
    deletedProductIds: productIds,
    cleanup,
  };
}

async function queueQueryTreeDelete(query, context) {
  const snapshot = await query.get();
  let deleteCount = 0;

  for (const doc of snapshot.docs) {
    if (context.queuedDeletes.has(doc.ref.path)) {
      continue;
    }

    deleteCount += 1;
    await queueDocumentTreeDelete(doc.ref, context);
  }

  return deleteCount;
}

async function queueDocumentTreeDelete(docRef, context) {
  if (context.queuedDeletes.has(docRef.path)) {
    return;
  }

  context.queuedDeletes.add(docRef.path);
  const subcollections = await docRef.listCollections();

  for (const collectionRef of subcollections) {
    const snapshot = await collectionRef.get();
    for (const childDoc of snapshot.docs) {
      await queueDocumentTreeDelete(childDoc.ref, context);
    }
  }

  context.cleanup.deletedDocuments += 1;
  context.writer.delete(docRef);
}

async function queueCollectionGroupDocDeletes(collectionId, productId, context) {
  const snapshot = await db
    .collectionGroup(collectionId)
    .where("productId", "==", productId)
    .get();

  snapshot.docs.forEach((doc) => {
    if (context.queuedDeletes.has(doc.ref.path)) {
      return;
    }

    context.queuedDeletes.add(doc.ref.path);
    context.cleanup.deletedDocuments += 1;
    context.writer.delete(doc.ref);
  });
}
