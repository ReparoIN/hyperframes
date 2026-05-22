#!/usr/bin/env bash
# Render all CallCards edu ads (ad-01 through ad-11).
# Run from the repo root: bash render-edu.sh
# Generates TTS for any ad missing a voiceover, then renders.

# Ensure Python313 (where kokoro-onnx lives) takes priority over miniconda
export PATH="/c/Users/Harish-Ops/AppData/Local/Programs/Python/Python313:/c/Users/Harish-Ops/AppData/Local/Programs/Python/Python313/Scripts:$PATH"

FORMAT="callcards-edu-ads"
DRAFT_FLAGS="--quality draft"

# ── pre-flight: check music ─────────────────────────────────────────────────
if [ ! -f "$FORMAT/shared/music.mp3" ]; then
  echo "ERROR: missing $FORMAT/shared/music.mp3"
  echo "Drop a music file there before rendering."
  exit 1
fi

# ── count ads ───────────────────────────────────────────────────────────────
TOTAL=0
for ad in "$FORMAT"/ad-*/; do
  [ -d "$ad" ] && TOTAL=$((TOTAL + 1))
done

mkdir -p "renders/draft/$FORMAT"

echo "=================================================="
echo " CallCards EDU Ads — draft render ($TOTAL ads)"
echo "=================================================="
echo ""

DONE=0
START=$(date +%s)

for ad in "$FORMAT"/ad-*/; do
  [ -d "$ad" ] || continue
  name=$(basename "$ad")
  out="renders/draft/$FORMAT/$name.mp4"
  DONE=$((DONE + 1))

  echo "[$DONE/$TOTAL] $name"

  # skip if output already exists
  if [ -f "$out" ]; then
    echo "  skip (already rendered)"
    continue
  fi

  # generate TTS if missing — section-aligned so audio drives slide timing
  if [ ! -f "$ad/assets/voiceover.mp3" ]; then
    echo "  → TTS (section-aligned)..."
    python sync-edu-tts.py "$name"
    if [ ! -f "$ad/assets/voiceover.mp3" ]; then
      echo "  ERROR: TTS failed for $name — skipping"
      continue
    fi
  fi

  # render
  echo "  → Rendering..."
  npx hyperframes@0.6.27 render "$ad" --output "$out" $DRAFT_FLAGS
  if [ $? -ne 0 ]; then
    echo "  ERROR: render failed for $name"
  else
    echo "  ✓ $out"
  fi
done

END=$(date +%s)
ELAPSED=$((END - START))
MINS=$((ELAPSED / 60))
SECS=$((ELAPSED % 60))

echo ""
echo "=================================================="
echo " Done. $TOTAL ads processed in ${MINS}m ${SECS}s"
echo " Output: renders/draft/$FORMAT/"
echo "=================================================="
