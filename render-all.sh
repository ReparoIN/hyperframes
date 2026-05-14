#!/usr/bin/env bash
# Render all 30 Call Cards ads in draft quality.
# Run from the repo root. Requires music.mp3 in each format's shared/ folder.
#
# Draft quality flag — adjust to taste:
#   --scale 0.5   half resolution, fastest
#   --fps 15      half framerate
#   (use both for maximum speed)
DRAFT_FLAGS="--scale 0.5"

FORMATS=(
  "callcards-edu-ads"
  "callcards-faceless-ads"
  "callcards-demo-ads"
)

# ── pre-flight: check music ─────────────────────────────────────────────────
for fmt in "${FORMATS[@]}"; do
  if [ ! -f "$fmt/shared/music.mp3" ]; then
    echo "ERROR: missing $fmt/shared/music.mp3"
    echo "Drop a music file there before rendering."
    exit 1
  fi
done

# ── count ads ───────────────────────────────────────────────────────────────
TOTAL=0
for fmt in "${FORMATS[@]}"; do
  for ad in "$fmt"/ad-*/; do
    [ -d "$ad" ] && TOTAL=$((TOTAL + 1))
  done
done

echo "=================================================="
echo " Call Cards — batch draft render ($TOTAL ads)"
echo "=================================================="
echo ""

DONE=0
START=$(date +%s)

for fmt in "${FORMATS[@]}"; do
  mkdir -p "renders/draft/$fmt"

  for ad in "$fmt"/ad-*/; do
    [ -d "$ad" ] || continue
    name=$(basename "$ad")
    out="renders/draft/$fmt/$name.mp4"
    DONE=$((DONE + 1))

    echo "[$DONE/$TOTAL] $fmt/$name"

    # skip if output already exists
    if [ -f "$out" ]; then
      echo "  skip (already rendered)"
      continue
    fi

    # generate TTS if missing
    if [ ! -f "$ad/assets/voiceover.mp3" ]; then
      echo "  → TTS..."
      npx hyperframes tts "$ad/voiceover-script.txt" --out "$ad/assets/voiceover.mp3"
    fi

    # render
    echo "  → Rendering..."
    npx hyperframes render "$ad/index.html" --out "$out" $DRAFT_FLAGS
    echo "  ✓ $out"
  done
done

END=$(date +%s)
ELAPSED=$((END - START))
MINS=$((ELAPSED / 60))
SECS=$((ELAPSED % 60))

echo ""
echo "=================================================="
echo " Done. $TOTAL ads rendered in ${MINS}m ${SECS}s"
echo " Output: renders/draft/"
echo "=================================================="
