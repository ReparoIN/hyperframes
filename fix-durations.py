"""
fix-durations.py
Run AFTER TTS is generated. For each ad:
  - Reads the actual voiceover.mp3 duration via ffprobe
  - Extends composition data-duration to VO duration + 1s buffer
  - Extends CTA clips (data-start="27" data-duration="3") to fill the remainder
"""
import glob, subprocess, re, math, os

def get_vo_duration(mp3_path):
    result = subprocess.run(
        ['ffprobe', '-v', 'quiet', '-show_entries', 'format=duration',
         '-of', 'default=noprint_wrappers=1', mp3_path],
        capture_output=True, text=True
    )
    for line in result.stdout.strip().splitlines():
        if 'duration=' in line:
            return float(line.split('=')[1])
    return None

changed = 0
skipped = 0

for html_path in sorted(glob.glob('callcards-*/ad-*/index.html')):
    mp3_path = html_path.replace('index.html', 'assets/voiceover.mp3').replace('\\', '/')
    html_path = html_path.replace('\\', '/')

    if not os.path.exists(mp3_path):
        print(f'  SKIP (no VO yet): {html_path}')
        skipped += 1
        continue

    dur = get_vo_duration(mp3_path)
    if dur is None:
        print(f'  SKIP (ffprobe failed): {html_path}')
        skipped += 1
        continue

    new_dur = math.ceil(dur) + 1   # 1s buffer after VO ends
    cta_dur = new_dur - 27         # CTA runs from 27s to end

    c = open(html_path, encoding='utf-8').read()

    # 1. All full-span clips (stage, audio tracks, solid bg fills) — duration was 30
    c = c.replace('data-duration="30"', f'data-duration="{new_dur}"')

    # 2. CTA section clips — were data-start="27" data-duration="3"
    c = c.replace(
        'data-start="27" data-duration="3"',
        f'data-start="27" data-duration="{cta_dur}"'
    )

    open(html_path, 'w', encoding='utf-8').write(c)
    print(f'  {html_path}: {dur:.1f}s → {new_dur}s  (CTA: {cta_dur}s from 27)')
    changed += 1

print(f'\n{changed} ads updated, {skipped} skipped.')
