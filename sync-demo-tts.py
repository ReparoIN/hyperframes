#!/usr/bin/env python3
"""
sync-demo-tts.py — Audio-driven video sync for CallCards demo ads.

All demo ads have 6 sections:
  hook | s1 | s2 | s3 | s4 | cta

For each ad, generates TTS per section at natural speed, measures actual
durations, updates HTML clip timing + GSAP triggers to match, then
concatenates sections + trailing silence into the full voiceover.

Usage:
  python sync-demo-tts.py                    # process all ads
  python sync-demo-tts.py ad-01              # single ad (substring match)
"""
import os, re, subprocess, tempfile, shutil, sys

ADS_DIR = "callcards-demo-ads"
CTA_DURATION = 3.0   # seconds to hold CTA slide after all speech ends

# On Windows, subprocess can't find .cmd shims directly -- resolve via which
NPX = shutil.which("npx") or "npx"


# ── helpers ───────────────────────────────────────────────────────────────────

def parse_sections(path):
    sections = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"\[(\d+):(\d+)-(\d+):(\d+)\]\s+(.+)", line.strip())
            if m:
                s_min, s_sec, e_min, e_sec, text = m.groups()
                start = int(s_min) * 60 + int(s_sec)
                end   = int(e_min) * 60 + int(e_sec)
                sections.append((start, end, text.strip()))
    return sections


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.returncode == 0, r.stdout.strip(), r.stderr.strip()


def get_duration(path):
    ok, out, _ = run([
        "ffprobe", "-v", "quiet",
        "-show_entries", "format=duration",
        "-of", "csv=p=0", path
    ])
    return float(out) if ok and out else 0.0


def generate_section_tts(text, out_mp3):
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".txt", delete=False, encoding="utf-8"
    ) as f:
        f.write(text)
        tmp_txt = f.name
    try:
        ok, _, err = run([NPX, "hyperframes@0.6.27", "tts", tmp_txt, "--output", out_mp3])
        if not ok:
            print(f"      npx error: {err[-200:]}")
        return ok
    finally:
        os.unlink(tmp_txt)


def fmt(x):
    return f"{round(x, 2):.2f}".rstrip("0").rstrip(".")


# ── HTML updater ──────────────────────────────────────────────────────────────

def update_element_attr(content, identifier, attr, new_val):
    """Find HTML tag by identifier string, update a specific attribute in it."""
    idx = content.find(identifier)
    if idx == -1:
        return content
    tag_start = content.rfind("<", 0, idx)
    tag_end   = content.find(">", idx) + 1
    tag = content[tag_start:tag_end]
    tag = re.sub(rf'{attr}="[^"]*"', f'{attr}="{new_val}"', tag)
    return content[:tag_start] + tag + content[tag_end:]


def update_gsap(content, selector, new_time):
    """Update the absolute-time argument on a tl.to() call."""
    esc = re.escape(selector)
    pattern = rf"(tl\.to\('{esc}',\s*\{{[^}}]*\}},)\s*[\d.]+"
    return re.sub(pattern, rf"\g<1>{fmt(new_time)}", content)


def update_html_timing(html_path, cumulative_times, total_duration):
    """
    Rewrite clip timing and GSAP triggers for a 6-section demo ad.

    Sections:  hook | s1  | s2  | s3  | s4  | cta
    Indices:    0     1     2     3     4     5
    cumulative_times has 7 entries: [0, t1, t2, t3, t4, t5, t6]
    """
    t1 = cumulative_times[1]   # hook ends
    t2 = cumulative_times[2]   # s1 ends
    t3 = cumulative_times[3]   # s2 ends
    t4 = cumulative_times[4]   # s3 ends
    t5 = cumulative_times[5]   # s4 ends = CTA speech starts

    with open(html_path, encoding="utf-8") as f:
        content = f.read()

    # total duration
    for ident in ['id="stage"', 'id="vo"', 'id="music"']:
        content = update_element_attr(content, ident, "data-duration", fmt(total_duration))

    # hook
    content = update_element_attr(content, 'class="hook-wrap clip"', "data-start",  "0")
    content = update_element_attr(content, 'class="hook-wrap clip"', "data-duration", fmt(t1))

    # steps
    for step_id, start, end in [
        ("s1", t1, t2), ("s2", t2, t3), ("s3", t3, t4), ("s4", t4, t5)
    ]:
        ident = f'id="{step_id}"'
        content = update_element_attr(content, ident, "data-start",    fmt(start))
        content = update_element_attr(content, ident, "data-duration", fmt(end - start))

    # cta
    content = update_element_attr(content, 'class="cta-wrap clip"', "data-start",  fmt(t5))
    content = update_element_attr(content, 'class="cta-wrap clip"', "data-duration", fmt(CTA_DURATION))

    # GSAP triggers
    content = update_gsap(content, "#ht",       0.3)
    content = update_gsap(content, "#s1",       t1 + 0.3)
    content = update_gsap(content, "#s2",       t2 + 0.3)
    content = update_gsap(content, "#s3",       t3 + 0.3)
    content = update_gsap(content, "#s4",       t4 + 0.3)
    content = update_gsap(content, ".cta-wrap", t5 + 0.2)

    with open(html_path, "w", encoding="utf-8") as f:
        f.write(content)

    print(
        f"  HTML: hook=0-{t1:.1f}s | s1={t1:.1f}-{t2:.1f}s | "
        f"s2={t2:.1f}-{t3:.1f}s | s3={t3:.1f}-{t4:.1f}s | "
        f"s4={t4:.1f}-{t5:.1f}s | cta={t5:.1f}s+{CTA_DURATION}s"
    )


# ── main per-ad processing ────────────────────────────────────────────────────

def process_ad(ad_dir):
    script_path = os.path.join(ad_dir, "voiceover-script.txt")
    out_path    = os.path.join(ad_dir, "assets", "voiceover.mp3")
    html_path   = os.path.join(ad_dir, "index.html")

    if not os.path.exists(script_path):
        print("  No voiceover script -- skipped")
        return False

    sections = parse_sections(script_path)
    if len(sections) != 6:
        print(f"  Expected 6 sections, got {len(sections)} -- skipped")
        return False

    os.makedirs(os.path.join(ad_dir, "assets"), exist_ok=True)
    tmpdir = tempfile.mkdtemp()

    try:
        section_files = []
        section_durs  = []

        for i, (start, end, text) in enumerate(sections):
            preview = text[:50] + ("..." if len(text) > 50 else "")
            print(f"    [{i+1}/6] {preview}")

            raw_mp3 = os.path.join(tmpdir, f"raw_{i}.mp3")
            if not generate_section_tts(text, raw_mp3):
                print(f"      ERROR: TTS failed for section {i+1}")
                return False

            dur = get_duration(raw_mp3)
            print(f"      {dur:.1f}s")
            section_files.append(raw_mp3)
            section_durs.append(dur)

        # Cumulative timestamps
        cumulative_times = [0]
        for d in section_durs:
            cumulative_times.append(cumulative_times[-1] + d)

        t5             = cumulative_times[5]   # CTA speech starts
        total_speech   = cumulative_times[6]
        total_duration = round(t5 + CTA_DURATION, 2)
        print(f"  Speech: {total_speech:.1f}s | cta_start={t5:.1f}s | total={total_duration}s")

        # Concatenate all sections
        concat_txt = os.path.join(tmpdir, "concat.txt")
        with open(concat_txt, "w") as f:
            for sf in section_files:
                f.write(f"file '{sf.replace(chr(92), '/')}'\n")

        joined_mp3 = os.path.join(tmpdir, "joined.mp3")
        ok, _, err = run([
            "ffmpeg", "-y", "-f", "concat", "-safe", "0",
            "-i", concat_txt, "-ar", "24000", "-ac", "1", joined_mp3
        ])
        if not ok:
            print(f"  ERROR concat: {err[-200:]}")
            return False

        # Pad with trailing silence to total_duration
        ok, _, err = run([
            "ffmpeg", "-y", "-i", joined_mp3,
            "-af", "apad", "-t", str(total_duration),
            "-ar", "24000", "-ac", "1",
            out_path
        ])
        if not ok:
            print(f"  ERROR padding: {err[-200:]}")
            return False

        print(f"  Audio: {get_duration(out_path):.1f}s -> {out_path}")

        if os.path.exists(html_path):
            update_html_timing(html_path, cumulative_times, total_duration)
        else:
            print("  WARN: index.html not found, skipping HTML update")

        return True

    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


# ── entry point ───────────────────────────────────────────────────────────────

filter_arg = sys.argv[1] if len(sys.argv) > 1 else None

for ad_name in sorted(os.listdir(ADS_DIR)):
    ad_dir = os.path.join(ADS_DIR, ad_name)
    if not os.path.isdir(ad_dir) or not ad_name.startswith("ad-"):
        continue
    if filter_arg and filter_arg not in ad_name:
        continue
    print(f"\n[{ad_name}]")
    process_ad(ad_dir)
