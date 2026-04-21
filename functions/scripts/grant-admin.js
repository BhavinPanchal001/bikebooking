#!/usr/bin/env node

const {initializeApp, applicationDefault, cert} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const fs = require("node:fs");
const path = require("node:path");

function readJsonFile(filePath) {
  const absolutePath = path.resolve(process.cwd(), filePath);
  const fileContents = fs.readFileSync(absolutePath, "utf8");
  return JSON.parse(fileContents);
}

function initializeFirebaseAdmin() {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (serviceAccountPath) {
    initializeApp({
      credential: cert(readJsonFile(serviceAccountPath)),
    });
    return;
  }

  initializeApp({
    credential: applicationDefault(),
  });
}

async function main() {
  const email = String(process.argv[2] || "").trim().toLowerCase();
  if (!email) {
    throw new Error(
      "Usage: node scripts/grant-admin.js <email>\n" +
        "Set FIREBASE_SERVICE_ACCOUNT=/absolute/path/to/service-account.json " +
        "or GOOGLE_APPLICATION_CREDENTIALS before running.",
    );
  }

  initializeFirebaseAdmin();

  const auth = getAuth();
  const db = getFirestore();
  const userRecord = await auth.getUserByEmail(email);
  const currentClaims = userRecord.customClaims || {};

  await auth.setCustomUserClaims(userRecord.uid, {
    ...currentClaims,
    admin: true,
  });

  await db.collection("admin_users").doc(userRecord.uid).set(
    {
      uid: userRecord.uid,
      email,
      role: "admin",
      active: true,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  console.log(`Admin access granted for ${email}`);
  console.log(`UID: ${userRecord.uid}`);
  console.log("Created/updated Firestore doc: admin_users/<uid>");
  console.log("Set custom claim: admin=true");
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
