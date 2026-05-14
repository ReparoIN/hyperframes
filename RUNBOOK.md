# Call Cards — Local Render Runbook

## What's in this repo

| Folder | Contents |
|---|---|
| `callcards-edu-ads/` | 10 educational ads (3-reason card format, 30s) |
| `callcards-faceless-ads/` | 10 app walkthrough ads (badge scanner → catalog → form → dashboard, 30s) |
| `callcards-demo-ads/` | 10 QR scan flow ads (share QR → card → follow-up → lead logged, 30s) |
| `callcards-ads/` | Ad copy SQLite DB — 50 hooks, 5 meats, 3 CTAs, 4 refinement passes |
| `render-all.sh` | Batch render script — TTS + render for all 30 ads |

All 30 ads are 1080×1920 (9:16), 30 seconds, with voiceover + background music.

---

## Prerequisites

### 1. Node.js
Version 18+ required.
```bash
node -v   # should be v18 or higher
```
Install from https://nodejs.org if needed.

### 2. HyperFrames CLI
```bash
npm install -g hyperframes
# or use npx (no install needed, just slower first run)
```

### 3. SQLite (optional — for browsing/editing ad copy)
```bash
# macOS
brew install sqlite
# Ubuntu
apt install sqlite3
```

---

## One-time setup

### Step 1 — Clone the repo
```bash
git clone https://github.com/ReparoIN/hyperframes.git
cd hyperframes
```

### Step 2 — Add music
Drop any royalty-free background track (MP3) into each format's shared folder.
All 10 ads in a format share one music file.
```bash
cp ~/your-music.mp3 callcards-edu-ads/shared/music.mp3
cp ~/your-music.mp3 callcards-faceless-ads/shared/music.mp3
cp ~/your-music.mp3 callcards-demo-ads/shared/music.mp3
```
The track should be at least 30 seconds. It loops automatically.

### Step 3 — Make the render script executable
```bash
chmod +x render-all.sh
```

---

## Render all 30 ads (draft quality)

```bash
./render-all.sh
```

This will, for each ad:
1. Generate TTS from `voiceover-script.txt` → `assets/voiceover.mp3`
2. Render `index.html` to `renders/draft/<format>/<ad-name>.mp4`

Outputs land in `renders/draft/`:
```
renders/
  draft/
    callcards-edu-ads/
      ad-01-pocket-competitor.mp4
      ad-02-fortune-booth.mp4
      ...
    callcards-faceless-ads/
      ...
    callcards-demo-ads/
      ...
```

**Already rendered?** The script skips ads that already have an output file.
**Already have TTS?** It skips `voiceover.mp3` generation if the file exists.

### Draft quality settings
Edit the top of `render-all.sh` to adjust speed vs. quality:
```bash
DRAFT_FLAGS="--scale 0.5"           # half resolution (default)
DRAFT_FLAGS="--scale 0.5 --fps 15"  # half resolution + half framerate (fastest)
DRAFT_FLAGS=""                       # full quality
```

---

## Render a single ad

```bash
# Generate TTS
npx hyperframes tts callcards-edu-ads/ad-01-pocket-competitor/voiceover-script.txt \
  --out callcards-edu-ads/ad-01-pocket-competitor/assets/voiceover.mp3

# Render (draft)
npx hyperframes render callcards-edu-ads/ad-01-pocket-competitor/index.html \
  --out renders/ad-01-edu.mp4 --scale 0.5

# Render (full quality)
npx hyperframes render callcards-edu-ads/ad-01-pocket-competitor/index.html \
  --out renders/ad-01-edu-hq.mp4
```

---

## Browse / edit ad copy

The ad copy database is at `callcards-ads/ads.db`.

```bash
cd callcards-ads
sqlite3 ads.db
```

Useful queries:
```sql
-- See all hooks
SELECT id, awareness_level, hook_text FROM hooks ORDER BY id;

-- India-specific hooks (flagged for global variant work)
SELECT id, hook_text FROM hooks WHERE notes LIKE '%INDIA-SPECIFIC%';

-- See all meats
SELECT id, title, script FROM meats;

-- See all CTAs
SELECT id, cta_text FROM ctas;
```

To apply the refinement SQLs manually:
```bash
sqlite3 ads.db < refine-v1.sql
sqlite3 ads.db < refine-v2.sql
sqlite3 ads.db < refine-v3.sql
sqlite3 ads.db < refine-v4.sql
```

---

## Ad map — 30 compositions

Same 10 hooks across all 3 formats:

| # | Folder name | Hook | Awareness |
|---|---|---|---|
| 01 | `ad-01-pocket-competitor` | Your card is in their pocket. Your competitor is in their phone. | Unaware |
| 02 | `ad-02-fortune-booth` | You spent a fortune on the booth. You lost the leads that were supposed to pay for it. | Unaware |
| 03 | `ad-03-wet-cards` | Wet cards. Misprinted cards. Forgotten cards. There's a better way. | Problem aware |
| 04 | `ad-04-paper-lost` | Paper cards get lost. Deals get lost with them. | Problem aware |
| 05 | `ad-05-lead-system` | Other apps give you a card. This gives you a complete lead system. | Solution aware |
| 06 | `ad-06-badge-scanning` | Most digital card apps don't have badge scanning. This one does. | Solution aware |
| 07 | `ad-07-print-vendor` | Your print vendor gets paid whether you close leads or not. We don't. | Competitor |
| 08 | `ad-08-money-closing` | The money you spend printing cards could be spent closing them. | Competitor |
| 09 | `ad-09-one-scan` | One scan. One second. Full lead captured. Let me show you. | Pattern interrupt |
| 10 | `ad-10-watch-this` | Before you order your next batch of business cards, watch this. | Pattern interrupt |

---

## What to do after draft renders

1. **Watch all 30** — note which hooks + formats feel strongest
2. **Pick top 5-10** for full-quality re-render (remove `--scale 0.5`)
3. **Upload TTS to check voice** — swap in a real voice actor recording if needed
4. **Tag winners in the DB** — update `status` in `ad_combinations` to `approved`
5. **Create global variants** — run SQL to find `INDIA-SPECIFIC` hooks and write neutral rewrites
