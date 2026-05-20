#!/usr/bin/env node
/**
 * task-flow: gen_dashboard.js
 * Generates a self-contained dashboard.html from tasks.db.
 *
 * Usage (from repo root):
 *   node .task-flow/scripts/gen_dashboard.js
 *   node .task-flow/scripts/gen_dashboard.js --repos ../cc-mark ../hyperframes
 *   node .task-flow/scripts/gen_dashboard.js --out /custom/path/dashboard.html
 *
 * Or: npm run tasks:dashboard
 *
 * Requires: npm install sqlite3
 */

const Database = require('sqlite3').Database;
const fs = require('fs');
const path = require('path');

// --- CLI args ---
const args = process.argv.slice(2);
const repoFlagIdx = args.indexOf('--repos');
const outFlagIdx = args.indexOf('--out');
const extraRepos = repoFlagIdx !== -1
  ? args.slice(repoFlagIdx + 1).filter(a => !a.startsWith('--'))
  : [];
const outFile = outFlagIdx !== -1 ? args[outFlagIdx + 1] : 'dashboard.html';

// --- Load tasks from a DB ---
function loadTasks(dbPath, repoName) {
  return new Promise((resolve) => {
    if (!fs.existsSync(dbPath)) return resolve([]);
    const db = new Database(dbPath, require('sqlite3').OPEN_READONLY);
    const cutoff = new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10);
    db.all(`
      SELECT id, title, status, owner, context, parent_id, blocked_by, updated_at
      FROM tasks
      ORDER BY
        CASE status
          WHEN 'needs_human' THEN 0
          WHEN 'in_progress' THEN 1
          WHEN 'pending'     THEN 2
          WHEN 'done'        THEN 3
        END, id
    `, (err, rows) => {
      db.close();
      if (err) return resolve([]);
      const tasks = (rows || [])
        .filter(r => !(r.status === 'done' && (r.updated_at || '').slice(0, 10) < cutoff))
        .map(r => ({ ...r, repo: repoName }));
      resolve(tasks);
    });
  });
}

// --- Load recent log entries from a DB ---
function loadLog(dbPath, repoName, limit = 40) {
  return new Promise((resolve) => {
    if (!fs.existsSync(dbPath)) return resolve([]);
    const db = new Database(dbPath, require('sqlite3').OPEN_READONLY);
    db.get(`SELECT name FROM sqlite_master WHERE type='table' AND name='task_log'`, (err, row) => {
      if (err || !row) { db.close(); return resolve([]); }
      db.all(`
        SELECT l.id, l.task_id, l.action, l.note, l.actor, l.created_at,
               t.title as task_title
        FROM task_log l
        LEFT JOIN tasks t ON t.id = l.task_id
        ORDER BY l.created_at DESC
        LIMIT ?
      `, [limit], (err2, rows) => {
        db.close();
        if (err2) return resolve([]);
        resolve((rows || []).map(r => ({ ...r, repo: repoName })));
      });
    });
  });
}

// --- Build HTML ---
function buildHtml(allTasks, allLog, repoNames, generatedAt) {
  const dataJson  = JSON.stringify(allTasks, null, 2);
  const logJson   = JSON.stringify(allLog,   null, 2);
  const reposJson = JSON.stringify(repoNames);

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Task Flow Dashboard</title>
<style>
  :root {
    --bg: #0f1117; --surface: #1a1d27; --surface2: #22263a; --border: #2e3347;
    --text: #e2e8f0; --muted: #7c85a2;
    --red: #f87171; --yellow: #fbbf24; --blue: #60a5fa; --green: #34d399; --purple: #a78bfa;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; font-size: 14px; line-height: 1.6; }
  header { padding: 20px 24px 16px; border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; }
  header h1 { font-size: 18px; font-weight: 600; }
  header .meta { color: var(--muted); font-size: 12px; }
  .toolbar { padding: 12px 24px; border-bottom: 1px solid var(--border); display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
  .repo-btn { padding: 4px 12px; border-radius: 20px; border: 1px solid var(--border); background: transparent; color: var(--muted); cursor: pointer; font-size: 12px; transition: all .15s; }
  .repo-btn.active { background: var(--surface2); color: var(--text); border-color: var(--blue); }
  .copy-all-btn { margin-left: auto; padding: 6px 16px; background: var(--blue); color: #fff; border: none; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 500; }
  .copy-all-btn:hover { opacity: .85; }
  .main { padding: 20px 24px; max-width: 960px; margin: 0 auto; }
  .section { margin-bottom: 28px; }
  .section-header { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: .08em; color: var(--muted); margin-bottom: 10px; display: flex; align-items: center; gap: 8px; }
  .badge { background: var(--surface2); padding: 2px 8px; border-radius: 10px; font-size: 11px; }
  .task-card { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 14px 16px; margin-bottom: 8px; }
  .task-card.sub { margin-left: 24px; border-left: 3px solid var(--purple); }
  .task-card.needs-human { border-left: 3px solid var(--red); }
  .task-card.in-progress { border-left: 3px solid var(--yellow); }
  .task-card.done { opacity: .55; }
  .task-top { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 6px; }
  .task-id { font-size: 11px; color: var(--muted); font-family: monospace; white-space: nowrap; margin-top: 2px; }
  .task-title { font-weight: 500; flex: 1; }
  .status-pill { font-size: 11px; padding: 2px 8px; border-radius: 10px; white-space: nowrap; font-weight: 500; }
  .pill-needs-human { background: rgba(248,113,113,.15); color: var(--red); }
  .pill-in-progress { background: rgba(251,191,36,.15); color: var(--yellow); }
  .pill-pending { background: rgba(96,165,250,.1); color: var(--blue); }
  .pill-done { background: rgba(52,211,153,.1); color: var(--green); }
  .task-meta { font-size: 12px; color: var(--muted); margin-bottom: 8px; }
  .task-context { font-size: 12px; color: var(--muted); background: var(--surface2); border-radius: 6px; padding: 8px 10px; white-space: pre-wrap; font-family: monospace; max-height: 120px; overflow-y: auto; margin-bottom: 10px; }
  .reply-area { display: flex; flex-direction: column; gap: 6px; }
  .reply-area label { font-size: 11px; color: var(--red); font-weight: 500; }
  .reply-row { display: flex; gap: 8px; }
  .reply-input { flex: 1; background: var(--surface2); border: 1px solid var(--border); border-radius: 6px; color: var(--text); font-size: 13px; padding: 7px 10px; font-family: inherit; resize: vertical; min-height: 36px; }
  .reply-input:focus { outline: none; border-color: var(--blue); }
  .copy-btn { padding: 6px 12px; background: var(--surface2); border: 1px solid var(--border); border-radius: 6px; color: var(--text); cursor: pointer; font-size: 12px; white-space: nowrap; }
  .copy-btn:hover { border-color: var(--blue); }
  .copy-btn.copied { color: var(--green); border-color: var(--green); }
  .progress-bar { height: 4px; background: var(--surface2); border-radius: 2px; margin-top: 6px; }
  .progress-fill { height: 100%; background: var(--purple); border-radius: 2px; }
  .empty { color: var(--muted); font-size: 13px; padding: 12px 0; }
  .log-list { display: flex; flex-direction: column; gap: 4px; }
  .log-entry { display: flex; gap: 10px; align-items: baseline; font-size: 12px; padding: 5px 0; border-bottom: 1px solid var(--border); }
  .log-entry:last-child { border-bottom: none; }
  .log-time { color: var(--muted); white-space: nowrap; font-family: monospace; flex-shrink: 0; }
  .log-action { padding: 1px 7px; border-radius: 8px; font-size: 11px; font-weight: 500; white-space: nowrap; flex-shrink: 0; }
  .log-created    { background: rgba(96,165,250,.12);  color: var(--blue); }
  .log-started    { background: rgba(251,191,36,.12);  color: var(--yellow); }
  .log-done       { background: rgba(52,211,153,.12);  color: var(--green); }
  .log-needs_human{ background: rgba(248,113,113,.12); color: var(--red); }
  .log-unblocked  { background: rgba(167,139,250,.12); color: var(--purple); }
  .log-wrap       { background: rgba(96,165,250,.08);  color: var(--muted); }
  .log-note { color: var(--text); flex: 1; }
  .log-actor { color: var(--muted); font-size: 11px; white-space: nowrap; }
  .log-repo  { color: var(--purple); font-size: 11px; margin-left: 4px; }
</style>
</head>
<body>
<header>
  <h1>⚡ Task Flow</h1>
  <div class="meta">Generated ${generatedAt}</div>
</header>
<div class="toolbar">
  <button class="repo-btn active" data-repo="all" onclick="filterRepo('all')">All repos</button>
  <span id="repo-buttons"></span>
  <button class="copy-all-btn" onclick="copyAll()">Copy All Replies</button>
</div>
<div class="main" id="main"></div>
<div class="main" style="max-width:960px;margin:0 auto;padding:0 24px 32px;">
  <div class="section">
    <div class="section-header">📋 Recent Activity <span class="badge" id="log-badge"></span></div>
    <div class="log-list" id="log-list"></div>
  </div>
</div>
<script>
const ALL_TASKS = ${dataJson};
const ALL_LOG   = ${logJson};
const REPO_NAMES = ${reposJson};
let activeRepo = 'all';

function filterRepo(repo) {
  activeRepo = repo;
  document.querySelectorAll('.repo-btn').forEach(b => b.classList.toggle('active', b.dataset.repo === repo));
  render();
}
function tasks() { return activeRepo === 'all' ? ALL_TASKS : ALL_TASKS.filter(t => t.repo === activeRepo); }
function statusLabel(s) { return {needs_human:'Needs Input',in_progress:'In Progress',pending:'Pending',done:'Done'}[s]||s; }
function pillClass(s) { return {needs_human:'pill-needs-human',in_progress:'pill-in-progress',pending:'pill-pending',done:'pill-done'}[s]||''; }
function cardClass(s) { return {needs_human:'needs-human',in_progress:'in-progress',done:'done'}[s]||''; }
function esc(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

function renderTask(t, isChild, tl) {
  const children = tl.filter(c => c.parent_id === t.id);
  const prog = children.length ? {done: children.filter(c=>c.status==='done').length, total: children.length} : null;
  const needsInput = t.status === 'needs_human';
  const repoTag = activeRepo === 'all' ? `<span style="color:var(--purple);font-size:11px;">[${t.repo}]</span> ` : '';

  const replyHtml = needsInput ? `
    <div class="reply-area">
      <label>↑ Your reply — fill in then Copy</label>
      <div class="reply-row">
        <textarea class="reply-input" id="reply-${t.id}">[TASK-${t.id}] </textarea>
        <button class="copy-btn" onclick="copyOne(${t.id})">Copy</button>
      </div>
    </div>` : '';

  const progressHtml = prog ? `
    <div class="task-meta">${prog.done}/${prog.total} sub-tasks done</div>
    <div class="progress-bar"><div class="progress-fill" style="width:${Math.round(prog.done/prog.total*100)}%"></div></div>` : '';

  return `
    <div class="task-card ${isChild?'sub':''} ${cardClass(t.status)}" data-repo="${t.repo}">
      <div class="task-top">
        <span class="task-id">#${t.id}</span>
        <span class="task-title">${repoTag}${esc(t.title)}</span>
        <span class="status-pill ${pillClass(t.status)}">${statusLabel(t.status)}</span>
      </div>
      ${t.updated_at ? `<div class="task-meta">Updated ${t.updated_at.slice(0,10)}</div>` : ''}
      ${t.context ? `<div class="task-context">${esc(t.context.trim())}</div>` : ''}
      ${progressHtml}
      ${replyHtml}
    </div>
    ${children.map(c => renderTask(c, true, tl)).join('')}
  `;
}

function render() {
  const tl = tasks();
  const topLevel = tl.filter(t => !t.parent_id);
  const groups = [
    {label:'🔴 Needs Your Input', filter: t => t.status==='needs_human'},
    {label:'🟡 In Progress',      filter: t => t.status==='in_progress'},
    {label:'⚪ Pending',           filter: t => t.status==='pending'},
    {label:'✅ Done (last 7 days)',filter: t => t.status==='done'},
  ];
  let html = '';
  for (const g of groups) {
    const items = topLevel.filter(g.filter);
    if (!items.length) continue;
    html += `<div class="section">
      <div class="section-header">${g.label} <span class="badge">${items.length}</span></div>
      ${items.map(t => renderTask(t, false, tl)).join('')}
    </div>`;
  }
  document.getElementById('main').innerHTML = html || '<div class="empty">No open tasks — all clear! 🎉</div>';
}

function copyOne(id) {
  const el = document.getElementById('reply-' + id);
  const v = el?.value.trim();
  if (!v || v === `[TASK-${id}]`) return;
  navigator.clipboard.writeText(v).then(() => {
    const btn = el.parentElement.querySelector('.copy-btn');
    btn.textContent = 'Copied!'; btn.classList.add('copied');
    setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 1500);
  });
}

function copyAll() {
  const lines = [];
  document.querySelectorAll('.reply-input').forEach(el => {
    const id = el.id.replace('reply-','');
    const v = el.value.trim();
    if (v && v !== `[TASK-${id}]`) lines.push(v);
  });
  if (!lines.length) { alert('Fill in at least one reply first.'); return; }
  navigator.clipboard.writeText(lines.join('\n')).then(() => {
    const btn = document.querySelector('.copy-all-btn');
    btn.textContent = 'Copied!';
    setTimeout(() => { btn.textContent = 'Copy All Replies'; }, 1500);
  });
}

REPO_NAMES.forEach(r => {
  const b = document.createElement('button');
  b.className = 'repo-btn'; b.dataset.repo = r; b.textContent = r;
  b.onclick = () => filterRepo(r);
  document.getElementById('repo-buttons').appendChild(b);
});

function renderLog() {
  const entries = activeRepo === 'all'
    ? ALL_LOG
    : ALL_LOG.filter(e => e.repo === activeRepo);

  document.getElementById('log-badge').textContent = entries.length;

  const actionLabel = {
    created:     'created',
    started:     'started',
    done:        'done',
    needs_human: 'blocked',
    unblocked:   'unblocked',
    wrap:        'wrap',
    context:     'note',
    sub_tasks:   'sub-tasks',
    orchestrator:'orchestrated',
  };

  const html = entries.length
    ? entries.map(e => {
        const label = actionLabel[e.action] || e.action;
        const taskRef = e.task_title ? `<b>#${e.task_id}</b> ${esc(e.task_title)}` : '';
        const repoTag = activeRepo === 'all' ? `<span class="log-repo">[${e.repo}]</span>` : '';
        const time = (e.created_at || '').slice(0, 16).replace('T', ' ');
        return `
          <div class="log-entry">
            <span class="log-time">${time}</span>
            <span class="log-action log-${e.action}">${label}</span>
            <span class="log-note">${taskRef}${e.note ? ' — ' + esc(e.note) : ''}${repoTag}</span>
            <span class="log-actor">${e.actor}</span>
          </div>`;
      }).join('')
    : '<div class="empty">No activity logged yet.</div>';

  document.getElementById('log-list').innerHTML = html;
}

const _origFilter = filterRepo;
filterRepo = (repo) => { _origFilter(repo); renderLog(); };

render();
renderLog();
</script>
</body>
</html>`;
}

// --- Main ---
async function main() {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const repoName = path.basename(repoRoot);
  const repoPaths = [[path.join(repoRoot, 'tasks.db'), repoName]];

  for (const rp of extraRepos) {
    const abs = path.resolve(rp);
    repoPaths.push([path.join(abs, 'tasks.db'), path.basename(abs)]);
  }

  const allTasks = [];
  const allLog   = [];
  const repoNames = [];
  for (const [dbPath, name] of repoPaths) {
    const tasks = await loadTasks(dbPath, name);
    const log   = await loadLog(dbPath, name);
    allTasks.push(...tasks);
    allLog.push(...log);
    if (!repoNames.includes(name)) repoNames.push(name);
  }
  allLog.sort((a, b) => (b.created_at || '').localeCompare(a.created_at || ''));

  const generatedAt = new Date().toLocaleString('en-US', {
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit'
  });

  const html = buildHtml(allTasks, allLog, repoNames, generatedAt);
  fs.writeFileSync(outFile, html, 'utf8');

  const needsHuman = allTasks.filter(t => t.status === 'needs_human').length;
  const inProgress = allTasks.filter(t => t.status === 'in_progress').length;
  const pending    = allTasks.filter(t => t.status === 'pending').length;

  console.log(`✓ ${outFile} generated`);
  console.log(`  🔴 Needs input: ${needsHuman}  🟡 In progress: ${inProgress}  ⚪ Pending: ${pending}`);
  if (needsHuman) console.log('  → Open dashboard.html, fill replies, then /unblock');
}

main().catch(err => { console.error(err); process.exit(1); });
