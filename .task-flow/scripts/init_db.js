#!/usr/bin/env node
/**
 * task-flow: init_db.js
 * Initialises tasks.db in the current repo and self-installs scripts.
 * Safe to run multiple times — won't overwrite existing data.
 *
 * First run (from skill or anywhere):
 *   node /path/to/init_db.js
 *
 * Subsequent runs (from repo):
 *   node .task-flow/scripts/init_db.js
 *   npm run tasks:init
 *
 * Requires: npm install sqlite3
 */

const { Database } = require('sqlite3');
const fs   = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const DB_PATH      = 'tasks.db';
const GITATTRIBUTES = '.gitattributes';
const SCRIPTS_DIR  = path.join('.task-flow', 'scripts');

// ── Schema ────────────────────────────────────────────────────────────────────

function initDb() {
  const existed = fs.existsSync(DB_PATH);
  const db = new Database(DB_PATH);

  db.serialize(() => {
    db.run('PRAGMA journal_mode=WAL');

    db.run(`
      CREATE TABLE IF NOT EXISTS tasks (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        title      TEXT    NOT NULL,
        status     TEXT    NOT NULL DEFAULT 'pending',
        owner      TEXT    NOT NULL DEFAULT 'ai',
        context    TEXT    NOT NULL DEFAULT '',
        parent_id  INTEGER REFERENCES tasks(id),
        blocked_by INTEGER REFERENCES tasks(id),
        updated_at TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    `);

    // Immutable event log — append only, never update rows
    db.run(`
      CREATE TABLE IF NOT EXISTS task_log (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id    INTEGER REFERENCES tasks(id),
        action     TEXT    NOT NULL,
        note       TEXT    NOT NULL DEFAULT '',
        actor      TEXT    NOT NULL DEFAULT 'ai',
        created_at TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    `, (err) => {
      if (err) { console.error('Schema error:', err.message); process.exit(1); }
      console.log(existed
        ? '✓ tasks.db already existed — schema ensured, data untouched'
        : '✓ tasks.db created (tasks + task_log, WAL mode)');
    });
  });

  db.close();
}

// ── Self-install scripts ──────────────────────────────────────────────────────

function selfInstall() {
  const thisDir = __dirname;
  const repoScriptsDir = path.resolve(SCRIPTS_DIR);

  if (!fs.existsSync(repoScriptsDir)) {
    fs.mkdirSync(repoScriptsDir, { recursive: true });
    console.log(`✓ Created ${SCRIPTS_DIR}/`);
  }

  const scripts = ['init_db.js', 'gen_dashboard.js'];
  let copied = 0;

  for (const file of scripts) {
    const src  = path.join(thisDir, file);
    const dest = path.join(repoScriptsDir, file);

    if (!fs.existsSync(src)) continue;          // running from repo already
    if (path.resolve(src) === path.resolve(dest)) continue; // same file

    if (!fs.existsSync(dest)) {
      fs.copyFileSync(src, dest);
      console.log(`✓ Installed ${file} → ${SCRIPTS_DIR}/`);
      copied++;
    } else {
      console.log(`✓ 