#!/usr/bin/env node
/**
 * task-flow: init_db.js
 * Initialises tasks.db in the current repo and self-installs scripts.
 * Safe to run multiple times -- won't overwrite existing data.
 *
 * First run (from skill or anywhere):
 *   node /path/to/init_db.js
 *
 * Subsequent runs (from repo):
 *   node .task-flow/scripts/init_db.js
 *   npm run tasks:init
 *
 * Requires: npm install better-sqlite3
 */

const fs   = require('fs');
const path = require('path');

const DB_PATH       = 'tasks.db';
const GITATTRIBUTES = '.gitattributes';
const SCRIPTS_DIR   = path.join('.task-flow', 'scripts');

// -- Schema ---------------------------------------------------------------

function initDb() {
  const existed = fs.existsSync(DB_PATH);
  let db;
  try {
    db = require('better-sqlite3')(DB_PATH);
  } catch (e) {
    console.error('Cannot open DB:', e.message);
    console.error('Run: npm install better-sqlite3');
    process.exit(1);
  }

  db.pragma('journal_mode = WAL');

  db.exec(`
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

  db.exec(`
    CREATE TABLE IF NOT EXISTS task_log (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      task_id    INTEGER REFERENCES tasks(id),
      action     TEXT    NOT NULL,
      note       TEXT    NOT NULL DEFAULT '',
      actor      TEXT    NOT NULL DEFAULT 'ai',
      created_at TEXT    NOT NULL DEFAULT (datetime('now'))
    )
  `);

  db.close();

  console.log(existed
    ? '✓ tasks.db already existed -- schema ensured, data untouched'
    : '✓ tasks.db created (tasks + task_log, WAL mode)');
}

// -- Self-install scripts -------------------------------------------------

function selfInstall() {
  const thisDir = __dirname;
  const repoScriptsDir = path.resolve(SCRIPTS_DIR);

  if (!fs.existsSync(repoScriptsDir)) {
    fs.mkdirSync(repoScriptsDir, { recursive: true });
    console.log('✓ Created ' + SCRIPTS_DIR + '/');
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
      console.log('✓ Installed ' + file + ' -> ' + SCRIPTS_DIR + '/');
      copied++;
    } else {
      console.log('✓ ' + file + ' already present -- skipping');
    }
  }

  if (copied === 0 && thisDir !== path.resolve(SCRIPTS_DIR)) {
    console.log('✓ Scripts already installed');
  }
}

// -- .gitattributes -------------------------------------------------------

function patchGitattributes() {
  const line = 'tasks.db binary';
  let existing = '';
  if (fs.existsSync(GITATTRIBUTES)) {
    existing = fs.readFileSync(GITATTRIBUTES, 'utf8');
  }
  if (existing.includes(line)) {
    console.log('✓ .gitattributes already has tasks.db binary');
    return;
  }
  const updated = existing.trimEnd() + (existing ? '\n' : '') + line + '\n';
  fs.writeFileSync(GITATTRIBUTES, updated, 'utf8');
  console.log('✓ Patched .gitattributes: tasks.db binary');
}

// -- package.json ---------------------------------------------------------

function patchPackageJson() {
  const pkgPath = path.resolve('package.json');
  if (!fs.existsSync(pkgPath)) {
    console.log('⚠ No package.json found -- skipping npm script patch');
    return;
  }

  const raw = fs.readFileSync(pkgPath, 'utf8');

  const scripts = {
    'tasks:init':      'node .task-flow/scripts/init_db.js',
    'tasks:dashboard': 'node .task-flow/scripts/gen_dashboard.js',
  };

  let updated = raw;
  let patched = 0;

  for (const [name, cmd] of Object.entries(scripts)) {
    if (updated.includes('"' + name + '"')) {
      console.log('✓ package.json already has ' + name);
      continue;
    }
    // Insert before closing } of "scripts" block
    const scriptsMatch = updated.match(/"scripts"\s*:\s*\{/);
    if (!scriptsMatch) {
      console.log('⚠ Could not find "scripts" block in package.json');
      break;
    }
    const insertAt = updated.indexOf(scriptsMatch[0]) + scriptsMatch[0].length;
    updated = updated.slice(0, insertAt) +
      '\n    "' + name + '": "' + cmd + '",' +
      updated.slice(insertAt);
    patched++;
  }

  if (patched > 0) {
    fs.writeFileSync(pkgPath, updated, 'utf8');
    console.log('✓ Patched package.json: added tasks:init, tasks:dashboard');
  }
}

// -- Main -----------------------------------------------------------------

selfInstall();
initDb();
patchGitattributes();
patchPackageJson();

console.log('');
console.log('Task Flow initialised. Next steps:');
console.log('  npm install better-sqlite3');
console.log('  npm run tasks:dashboard   # generate dashboard.html');
console.log('  open dashboard.html');
