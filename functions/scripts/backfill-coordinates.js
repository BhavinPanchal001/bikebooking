#!/usr/bin/env node
/**
 * One-time backfill script: geocodes products that have a location text
 * but are missing latitude/longitude, using Nominatim (free, no API key).
 *
 * Usage:
 *   FIREBASE_SERVICE_ACCOUNT=/path/to/service-account.json \
 *   node scripts/backfill-coordinates.js [--dry-run]
 *
 * --dry-run  : Print what would be updated without writing to Firestore.
 */

const {initializeApp, cert} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const https = require("node:https");
const fs = require("node:fs");
const path = require("node:path");

const DRY_RUN = process.argv.includes("--dry-run");
const NOMINATIM_BASE = "https://nominatim.openstreetmap.org/search";
const USER_AGENT = "BikeBookingBackfill/1.0 (internal admin script)";
const RATE_LIMIT_MS = 1100; // Nominatim policy: max 1 req/sec

function readJsonFile(filePath) {
  const absolutePath = path.resolve(process.cwd(), filePath);
  return JSON.parse(fs.readFileSync(absolutePath, "utf8"));
}

function initFirebase() {
  const svcAccPath = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!svcAccPath) {
    throw new Error(
      "Set FIREBASE_SERVICE_ACCOUNT=/path/to/service-account.json before running.",
    );
  }
  initializeApp({credential: cert(readJsonFile(svcAccPath))});
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function httpGet(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(
      url,
      {headers: {"User-Agent": USER_AGENT}},
      (res) => {
        let body = "";
        res.on("data", (chunk) => (body += chunk));
        res.on("end", () => {
          if (res.statusCode !== 200) {
            reject(new Error(`HTTP ${res.statusCode} for ${url}`));
          } else {
            try {
              resolve(JSON.parse(body));
            } catch (e) {
              reject(new Error(`JSON parse error: ${e.message}`));
            }
          }
        });
      },
    );
    req.on("error", reject);
  });
}

function cleanLocation(locationText) {
  let text = locationText.trim();

  // Remove Google Plus Codes (e.g. "27XC+Q5P, " or "QW9H+HJF, ")
  text = text.replace(/^[A-Z0-9]{4,8}\+[A-Z0-9]{2,3},?\s*/i, "");

  // Remove leading street numbers (e.g. "32, " or "No 37 ")
  text = text.replace(/^(No\.?\s*)?\d+[A-Za-z]?,?\s+/i, "");

  // Remove PIN codes (6-digit Indian postal codes)
  text = text.replace(/\b\d{6}\b,?\s*/g, "");

  // Remove trailing/duplicate "India"
  text = text.replace(/,?\s*India\s*$/i, "").trim();
  text = text.replace(/,?\s*India\s*,/gi, ",").trim();

  return text.trim().replace(/,\s*,/g, ",").replace(/,\s*$/, "").trim();
}

function simplifyLocation(cleanedText) {
  // Keep only the last 2 comma-separated parts (usually city, state)
  const parts = cleanedText.split(",").map((p) => p.trim()).filter(Boolean);
  if (parts.length <= 2) return null; // already simple
  return parts.slice(-2).join(", ");
}

async function geocodeText(text) {
  const query = encodeURIComponent(`${text}, India`);
  const url = `${NOMINATIM_BASE}?q=${query}&format=json&limit=1&addressdetails=0`;
  const results = await httpGet(url);
  if (!Array.isArray(results) || results.length === 0) return null;
  const {lat, lon} = results[0];
  const latitude = parseFloat(lat);
  const longitude = parseFloat(lon);
  if (isNaN(latitude) || isNaN(longitude)) return null;
  return {latitude, longitude};
}

async function geocode(locationText) {
  const cleaned = cleanLocation(locationText);
  if (!cleaned || cleaned.length < 3) return null;

  // First try with full cleaned text
  let coords = await geocodeText(cleaned);
  if (coords) return {coords, usedText: cleaned};

  await sleep(RATE_LIMIT_MS);

  // Retry with simplified city, state only
  const simplified = simplifyLocation(cleaned);
  if (!simplified) return null;

  coords = await geocodeText(simplified);
  if (coords) return {coords, usedText: simplified};

  return null;
}

async function main() {
  initFirebase();
  const db = getFirestore();

  console.log(`Mode: ${DRY_RUN ? "DRY RUN (no writes)" : "LIVE"}`);
  console.log("Fetching products missing coordinates...\n");

  const snapshot = await db.collection("products").get();

  const missing = snapshot.docs.filter((doc) => {
    const d = doc.data();
    const hasLocation =
      typeof d.location === "string" && d.location.trim().length > 0;
    const hasCoords =
      typeof d.latitude === "number" && typeof d.longitude === "number";
    return hasLocation && !hasCoords;
  });

  console.log(`Found ${missing.length} products without coordinates.\n`);

  let updated = 0;
  let failed = 0;
  let skipped = 0;

  for (const doc of missing) {
    const data = doc.data();
    const location = data.location.trim();
    process.stdout.write(`[${doc.id}] "${location}" -> `);

    let result;
    try {
      result = await geocode(location);
    } catch (err) {
      console.log(`ERROR: ${err.message}`);
      failed++;
      await sleep(RATE_LIMIT_MS);
      continue;
    }

    if (!result) {
      console.log("NOT FOUND");
      skipped++;
      await sleep(RATE_LIMIT_MS);
      continue;
    }

    const {coords, usedText} = result;
    const suffix = usedText !== location ? ` (via "${usedText}")` : "";
    console.log(`lat=${coords.latitude.toFixed(5)}, lng=${coords.longitude.toFixed(5)}${suffix}`);

    if (!DRY_RUN) {
      await doc.ref.update({
        latitude: coords.latitude,
        longitude: coords.longitude,
      });
      updated++;
    } else {
      updated++;
    }

    await sleep(RATE_LIMIT_MS);
  }

  console.log("\n=== Summary ===");
  console.log(`Total missing : ${missing.length}`);
  console.log(`Updated       : ${updated}${DRY_RUN ? " (dry run)" : ""}`);
  console.log(`Not found     : ${skipped}`);
  console.log(`Errors        : ${failed}`);
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : String(err));
  process.exitCode = 1;
});
