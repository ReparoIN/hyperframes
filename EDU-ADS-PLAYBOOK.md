# Edu Ads Production Playbook

Learnings from producing the 11 CallCards edu ads. Apply to any new script batch.

---

## Pipeline overview

```
voiceover-script.txt
       ↓
sync-edu-tts.py          ← generates per-section TTS, updates HTML timing
       ↓
assets/voiceover.mp3     ← 30s (or t_cta + 5s) audio, section-locked
       ↓
render-edu.sh            ← calls sync script, then hyperframes render
       ↓
renders/draft/callcards-edu-ads/ad-XX.mp4
```

---

## Voiceover script format

```
Title line
Subtitle line
Duration: 30s | Format: 9:16 | Hook: unaware

[0:00-0:06] Hook text spoken here.

[0:06-0:13] Reason 1 text spoken here.

[0:13-0:20] Reason 2 text.

[0:20-0:27] Reason 3 text.

[0:27-0:30] Get your free digital card at call dot cards.
```

**Rules:**
- TTS reads only timestamped `[MM:SS-MM:SS]` lines — headers are ignored by the sync script
- Say **"call dot cards"** in the CTA line, not "call.cards" (TTS reads the dot as a pause otherwise)
- The visual HTML still shows `call.cards` — TTS text and visual text are separate concerns

---

## Three HTML layouts

All 11 ads share these three structures. Know which you're working with:

| Layout | Sections | HTML elements | Ads |
|--------|----------|---------------|-----|
| 3-card | 5 (hook, r1, r2, r3, cta) | `#r1` `#r2` `#r3` `.meat-hd` | 01 02 05 06 08 |
| 2-card | 4 (hook, r1, r2, cta) | `#r1` `#r2` `.meat-hd` | 03 04 07 09 |
| scard  | 3 (hook, main, cta) | `.scard` | 10 11 |

The sync script auto-detects layout from section count and updates the right GSAP triggers.

---

## Why section-aligned TTS matters

**The problem:** Single-pass TTS generates continuous speech — it has no concept of section boundaries. So "reason 1" audio might finish at 9s even though the HTML card reveal is at 13s. Everything drifts.

**The fix:** `sync-edu-tts.py` generates TTS per section, measures each section's actual duration, computes cumulative timestamps, then rewrites the HTML clip timing and GSAP triggers to match. Cards appear exactly when the audio starts talking about them.

**Timing formula:**
- `t_hook` = duration of section 1 (hook speech)
- `t_r1` = t_hook + section 2 duration
- `t_r2` = t_r1 + section 3 duration  
- `t_r3` = t_r2 + section 4 duration (5-section only)
- `t_cta` = cumulative_times[n-1]
- Video total = `t_cta + CTA_DURATION` (currently 5s)

---

## sync-edu-tts.py — what it does per ad

1. Parses `voiceover-script.txt` for timestamped sections
2. Generates TTS for each section to a temp `.mp3`
3. Measures actual duration with `ffprobe`
4. Concatenates all sections (no padding between sections)
5. Pads trailing silence to `t_cta + CTA_DURATION`
6. Writes `assets/voiceover.mp3`
7. Updates `index.html`:
   - `data-start` / `data-duration` on all clip elements
   - `data-duration` on stage, `<audio id="vo">`, `<audio id="music">`
   - GSAP timeline trigger times for each card reveal and CTA

**To run:**
```bash
# All ads
python sync-edu-tts.py

# One ad
python sync-edu-tts.py ad-07
```

---

## render-edu.sh — what it does

```bash
# For each ad/:
#   if voiceover.mp3 missing → call sync-edu-tts.py (generates TTS + updates HTML)
#   render → renders/draft/callcards-edu-ads/ad-XX.mp4
bash render-edu.sh
```

The render step reads `index.html` for timing — so updating HTML without deleting voiceover.mp3 lets you re-render visuals without re-running TTS.

**Selective re-render (visual-only change, TTS intact):**
```bash
rm renders/draft/callcards-edu-ads/ad-01*.mp4
npx hyperframes@0.6.27 render callcards-edu-ads/ad-01-pocket-competitor \
  --output renders/draft/callcards-edu-ads/ad-01-pocket-competitor.mp4 --quality draft
```

---

## CTA design — URL bar

The CTA slide uses a browser-style address bar instead of a pill button.

**CSS:**
```css
.url-bar    { background:#e8eef5; border-radius:16px; padding:28px 56px; display:flex; align-items:center }
.url-prefix { font-size:44px; font-weight:500; color:#94a3b8; letter-spacing:0 }
.url-domain { font-size:52px; font-weight:800; color:#0d1f35; letter-spacing:-0.5px }
```

**HTML:**
```html
<div class="url-bar">
  <span class="url-prefix">https://</span>
  <span class="url-domain">call.cards</span>
</div>
```

- `#e8eef5` bar on `#0d1f35` background reads instantly as a browser address bar
- `#94a3b8` prefix (slate) mirrors how Chrome dims the scheme
- `#0d1f35` domain (brand navy) — not brand green, which reads as a link/error on a light bar
- No browser brand icon needed — the bar shape + `https://` is the signal

---

## Logo watermark

Copy the logo to the **format's shared folder** before referencing it. Spaces in filenames break the renderer's asset copy.

```bash
cp "cc light.png" callcards-edu-ads/shared/cc-light.png
```

**HTML** (add before closing `</div>` of stage):
```html
<img id="watermark" src="../shared/cc-light.png"
  style="position:absolute;bottom:48px;right:48px;width:128px;opacity:0.55;pointer-events:none;z-index:100">
```

Reference pattern mirrors `../shared/music.mp3` — consistent with how all shared assets work.

---

## Windows gotchas

| Problem | Fix |
|---------|-----|
| `npx` not found in subprocess | Use `shutil.which("npx")` to resolve the `.cmd` path |
| TTS reads file path instead of content | `mktemp` must use `--suffix=.txt`; hyperframes TTS identifies files by extension |
| Unicode in print crashes | Avoid `→`, `✓` etc. in print statements — Windows cp1252 terminal can't encode them |
| Regex `\1` + digit = wrong group ref | Use `\g<1>` instead of `\1` in `re.sub` replacements |
| Python313 vs miniconda clash | Export PATH with Python313 first: `export PATH="/c/Users/.../Python313:$PATH"` |

---

## PATH fix (required in every shell script)

```bash
export PATH="/c/Users/Harish-Ops/AppData/Local/Programs/Python/Python313:/c/Users/Harish-Ops/AppData/Local/Programs/Python/Python313/Scripts:$PATH"
```

kokoro-onnx (the TTS engine) is installed in Python313. Miniconda's Python has a broken `encodings` module and must not take priority.

---

## Starting a new ad format

1. Create `callcards-[format]-ads/` with `shared/music.mp3` and `shared/cc-light.png`
2. Write `voiceover-script.txt` per ad following the `[MM:SS-MM:SS]` format
3. Build `index.html` using one of the three layout templates
4. Copy `render-edu.sh` → `render-[format].sh`, update `FORMAT=` variable
5. Copy `sync-edu-tts.py` → `sync-[format]-tts.py` if the layout differs significantly
6. Run `bash render-[format].sh`
