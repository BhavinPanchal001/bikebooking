#!/usr/bin/env python3
"""Generate assets/db/locations.db from the India postal CSV.

Mapping:
  statename  -> states.name
  district   -> cities.name
  officename -> areas.name  (+ latitude / longitude)

Tamil Nadu data is PRESERVED from the existing database (user-curated).
All other states are REBUILT from the CSV postal data.

Usage:
  python3 tools/import_postal_db.py "/path/to/postal.csv"
"""
import csv
import os
import shutil
import sqlite3
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DB_PATH = os.path.join(PROJECT_ROOT, "assets", "db", "locations.db")

# State to keep untouched. PRESERVE_STATE is the name as stored in the existing
# DB (Title Case); PRESERVE_STATE_CSV is the raw name as found in the CSV.
PRESERVE_STATE = "Tamil Nadu"
PRESERVE_STATE_CSV = "TAMIL NADU"

SMALL_WORDS = {"and", "of", "the"}

SCHEMA = """
PRAGMA foreign_keys = ON;

CREATE TABLE states (
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  TEXT NOT NULL UNIQUE
);

CREATE TABLE cities (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  name      TEXT NOT NULL,
  state_id  INTEGER NOT NULL,
  FOREIGN KEY (state_id) REFERENCES states(id),
  UNIQUE(name, state_id)
);

CREATE TABLE areas (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  name      TEXT NOT NULL,
  city_id   INTEGER NOT NULL,
  latitude  REAL,
  longitude REAL,
  FOREIGN KEY (city_id) REFERENCES cities(id),
  UNIQUE(name, city_id)
);

CREATE INDEX idx_cities_state_id ON cities(state_id);
CREATE INDEX idx_areas_city_id ON areas(city_id);
CREATE INDEX idx_states_name ON states(name);
CREATE INDEX idx_cities_name ON cities(name);
CREATE INDEX idx_areas_name ON areas(name);
"""


def title_case(value: str) -> str:
    """Title-case a name, keeping connector words (and/of/the) lowercase."""
    value = " ".join(value.split())
    words = value.lower().split(" ")
    out = []
    for i, word in enumerate(words):
        if i != 0 and word in SMALL_WORDS:
            out.append(word)
        else:
            out.append(word.capitalize())
    return " ".join(out)


def parse_coord(value):
    if value is None:
        return None
    value = value.strip()
    if value == "" or value.upper() == "NA":
        return None
    try:
        return float(value)
    except ValueError:
        return None


def extract_preserved(old_db_path):
    """Return (cities, areas) for the preserved state from the existing DB.

    cities: list of city names
    areas:  list of (area_name, city_name, lat, lng)
    """
    if not os.path.exists(old_db_path):
        return [], []
    conn = sqlite3.connect(old_db_path)
    try:
        cur = conn.cursor()
        cur.execute("SELECT id FROM states WHERE name = ?", (PRESERVE_STATE,))
        row = cur.fetchone()
        if not row:
            return [], []
        state_id = row[0]
        cur.execute("SELECT id, name FROM cities WHERE state_id = ?", (state_id,))
        city_rows = cur.fetchall()
        cities = [name for (_cid, name) in city_rows]
        areas = []
        for cid, cname in city_rows:
            cur.execute(
                "SELECT name, latitude, longitude FROM areas WHERE city_id = ?",
                (cid,),
            )
            for (aname, lat, lng) in cur.fetchall():
                areas.append((aname, cname, lat, lng))
        return cities, areas
    finally:
        conn.close()


def main():
    if len(sys.argv) < 2:
        print('Usage: python3 tools/import_postal_db.py "<csv_path>"')
        sys.exit(1)
    csv_path = sys.argv[1]
    if not os.path.exists(csv_path):
        print(f"CSV not found: {csv_path}")
        sys.exit(1)

    # 1. Pull the preserved Tamil Nadu data from the current DB.
    tn_cities, tn_areas = extract_preserved(DB_PATH)
    print(f"Preserved {PRESERVE_STATE}: {len(tn_cities)} cities, {len(tn_areas)} areas")

    # 2. Build a fresh DB at a temp path.
    tmp_path = DB_PATH + ".new"
    if os.path.exists(tmp_path):
        os.remove(tmp_path)
    os.makedirs(os.path.dirname(tmp_path), exist_ok=True)

    conn = sqlite3.connect(tmp_path)
    conn.executescript(SCHEMA)
    cur = conn.cursor()

    state_ids = {}        # state_name -> id
    city_ids = {}         # (state_id, city_name) -> id

    def get_state_id(name):
        sid = state_ids.get(name)
        if sid is not None:
            return sid
        cur.execute("INSERT OR IGNORE INTO states(name) VALUES(?)", (name,))
        cur.execute("SELECT id FROM states WHERE name = ?", (name,))
        sid = cur.fetchone()[0]
        state_ids[name] = sid
        return sid

    def get_city_id(state_id, name):
        key = (state_id, name)
        cid = city_ids.get(key)
        if cid is not None:
            return cid
        cur.execute(
            "INSERT OR IGNORE INTO cities(name, state_id) VALUES(?, ?)",
            (name, state_id),
        )
        cur.execute(
            "SELECT id FROM cities WHERE name = ? AND state_id = ?",
            (name, state_id),
        )
        cid = cur.fetchone()[0]
        city_ids[key] = cid
        return cid

    # 2a. Re-insert preserved Tamil Nadu first.
    tn_state_id = get_state_id(PRESERVE_STATE)
    for cname in tn_cities:
        get_city_id(tn_state_id, cname)
    for (aname, cname, lat, lng) in tn_areas:
        cid = get_city_id(tn_state_id, cname)
        cur.execute(
            "INSERT OR IGNORE INTO areas(name, city_id, latitude, longitude) "
            "VALUES(?,?,?,?)",
            (aname, cid, lat, lng),
        )

    # 3. Import the CSV (skip Tamil Nadu + invalid rows).
    rows_read = 0
    rows_imported = 0
    rows_skipped = 0
    with open(csv_path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows_read += 1
            state_raw = (r.get("statename") or "").strip()
            district_raw = (r.get("district") or "").strip()
            office_raw = (r.get("officename") or "").strip()

            if not state_raw or state_raw.upper() == "NA":
                rows_skipped += 1
                continue
            if state_raw.upper() == PRESERVE_STATE_CSV:
                rows_skipped += 1
                continue
            if not district_raw or district_raw.upper() == "NA":
                rows_skipped += 1
                continue

            state_name = title_case(state_raw)
            city_name = title_case(district_raw)
            sid = get_state_id(state_name)
            cid = get_city_id(sid, city_name)

            if office_raw and office_raw.upper() != "NA":
                area_name = " ".join(office_raw.split())
                lat = parse_coord(r.get("latitude"))
                lng = parse_coord(r.get("longitude"))
                cur.execute(
                    "INSERT OR IGNORE INTO areas(name, city_id, latitude, longitude) "
                    "VALUES(?,?,?,?)",
                    (area_name, cid, lat, lng),
                )
            rows_imported += 1

    conn.commit()

    n_states = cur.execute("SELECT COUNT(*) FROM states").fetchone()[0]
    n_cities = cur.execute("SELECT COUNT(*) FROM cities").fetchone()[0]
    n_areas = cur.execute("SELECT COUNT(*) FROM areas").fetchone()[0]
    conn.close()

    # 4. Atomically replace the old DB.
    shutil.move(tmp_path, DB_PATH)

    print(f"Rows read: {rows_read}, imported: {rows_imported}, skipped: {rows_skipped}")
    print(f"DB written: {DB_PATH}")
    print(f"  states={n_states} cities={n_cities} areas={n_areas}")


if __name__ == "__main__":
    main()
