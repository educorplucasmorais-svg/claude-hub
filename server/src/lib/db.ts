import Database from 'better-sqlite3'
import path from 'path'
import fs from 'fs'

const DATA_DIR = path.join(__dirname, '../../data')
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true })

const DB_PATH = path.join(DATA_DIR, 'hub.db')

const db = new Database(DB_PATH)
db.pragma('journal_mode = WAL')
db.pragma('foreign_keys = ON')

// ─── Schema ──────────────────────────────────────────────
db.exec(`
  CREATE TABLE IF NOT EXISTS generated_sites (
    id          TEXT PRIMARY KEY,
    title       TEXT NOT NULL,
    prompt      TEXT NOT NULL,
    site_type   TEXT NOT NULL DEFAULT 'landing',
    color_scheme TEXT NOT NULL DEFAULT 'dark',
    model       TEXT NOT NULL DEFAULT 'gpt-4o',
    html        TEXT NOT NULL,
    html_size   INTEGER NOT NULL DEFAULT 0,
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    opened_at   TEXT,
    deployed    INTEGER NOT NULL DEFAULT 0,
    deploy_url  TEXT
  );

  CREATE TABLE IF NOT EXISTS prompt_logs (
    id         TEXT PRIMARY KEY,
    feature    TEXT NOT NULL,
    model      TEXT NOT NULL,
    prompt     TEXT NOT NULL,
    response   TEXT NOT NULL DEFAULT '',
    tokens     INTEGER,
    duration   INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS notes (
    id         TEXT PRIMARY KEY,
    title      TEXT NOT NULL,
    content    TEXT NOT NULL,
    tags       TEXT NOT NULL DEFAULT '[]',
    source     TEXT NOT NULL DEFAULT 'manual',
    synced_at  TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
`)

export default db
