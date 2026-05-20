# CLAUDE.md — hyperframes

Local video render pipeline for call.cards ads and product demos.

## What lives here

- Shell render scripts (`render-all.sh`, per-project render scripts)
- TTS configs and audio assets
- Video scripts and storyboards
- Rendered video outputs (`renders/`)
- Ad copy SQLite DB (`callcards-ads/`)

## Key folders

- `callcards-edu-ads/` — educational/explainer ad variants
- `callcards-faceless-ads/` — faceless/voiceover ad variants
- `callcards-demo-ads/` — product demo ad variants
- `callcards-ads/` — ad copy SQLite DB (hooks, meats, CTAs)
- `renders/` — final rendered video outputs
- `shared/` — shared assets (fonts, music, logos)

## Rules

- Scripts, storyboards, and ad copy go in the relevant ad folder or repo root — **not** in `renders/`
- `renders/` is output-only — never put source files there
- This project is **shell + Python** — do not create Node.js files here
- Product truth lives in `../expo/landing-copy-draft.md` — read it before writing any scripts or ad copy

## Codegraph — Code Navigation

The codegraph MCP server is configured for this repo. Use it to navigate render scripts and configs.

**When to use:**
- Finding a specific render function or config variable → `mcp__codegraph__search_symbols`
- Locating a script by name → `mcp__codegraph__search_files`
- Finding what references a shared asset or helper → `mcp__codegraph__find_references`

The index will be built the first time VS Code opens this folder with the codegraph extension active.

## Task Flow — Session Protocol

This repo uses `tasks.db` (SQLite, committed to git) as shared working memory across Claude sessions.

**At the start of every session**, read open tasks before doing anything else — the DB tells you what to work on, no need to ask:
```bash
sqlite3 tasks.db "SELECT id,title,status,owner,context FROM tasks WHERE status!='done' ORDER BY CASE status WHEN 'needs_human' THEN 0 WHEN 'in_progress' THEN 1 WHEN 'pending' THEN 2 END, id"
```

Or regenerate the full HTML dashboard:
```bash
npm run tasks:dashboard  # requires: npm install (one-time, for sqlite3)
```

**Key commands:**
- `/wrap` — end of session: update context (DID/DECIDED/NEXT), commit DB, regenerate dashboard
- `/unblock [paste]` — process `[TASK-N] response` lines from dashboard, flip tasks to pending, immediately fan out sub-agents

Note: `tasks.db` is for Claude task state only. The ad copy DB lives in `callcards-ads/`. The pipeline itself remains shell + Python — task-flow management scripts are the only Node.js in this repo.

**Full protocol** (status transitions, orchestrator, context template, sub-tasks) lives in the `task-flow` Cowork skill.
