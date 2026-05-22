#!/usr/bin/env python3
"""
sync-edu-tts.py — Audio-driven video sync for CallCards edu ads.

Supports three ad layouts:
  5 sections / 3 r-cards  — ads 01 02 05 06 08
  4 sections / 2 r-cards  — ads 03 04 07 09
  3 sections / 1 s-card   — ads 10 11

For each ad, generates TTS per section at natural speed, measures actual
durations, updates HTML clip timing + GSAP triggers to match, then
concatenates sections + trailing silence into a 30-second voiceover.

Usage:
  python sync-edu-tts.py                    # process all ads
  python sync-edu-tts.py ad-01              # single ad (substring match)
"""
import os, re, subprocess, tempfile, shutil, sys

ADS_DIR = "callcards-edu-ads"
CTA_DURATION = 5.0   # seconds to hold the CTA slide after voiceover ends

# On Windows, subprocess can't find .cmd shims directly -- resolve via which
NPX = shutil.which("npx") or "npx"


# ── helpers ──────────────────────────────────────────────────────────────────

def parse_sections(path):
    sections = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"\[(\d+):(\d+)-(\d+):(\d+)\]\s+(.+)", line.strip())
            if m:
                s_min, s_sec, e_min, e_sec, text = m.groups()
                start = int(s_min) * 60 + int(s_sec)
                end = int(e_min) * 60 + int(e_sec)
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
    """Round to 2 dp, strip trailing zeros."""
    return f"{round(x, 2):.2f}".rstrip("0").rstrip(".")


# ── HTML updater ─────────────────────────────────────────────────────────────

def update_element_attr(content, identifier, attr, new_val):
    """Find HTML tag by identifier string, update a specific attribute in it.
    Safe to call when identifier doesn't exist -- returns content unchanged."""
    idx = content.find(identifier)
    if idx == -1:
        return content
    tag_start = content.rfind("<", 0, idx)
    tag_end = content.find(">", idx) + 1
    tag = content[tag_start:tag_end]
    tag = re.sub(rf'{attr}="[^"]*"', f'{attr}="{new_val}"', tag)
    return content[:tag_start] + tag + content[tag_end:]


def update_gsap(content, selector, new_time):
    """Update the absolute-time argument on a tl.to() call.
    Safe to call when selector doesn't exist -- returns content unchanged."""
    esc = re.escape(selector)
    pattern = rf"(tl\.to\('{esc}',\s*\{{[^}}]*\}},)\s*[\d.]+"
    return re.sub(pattern, rf"\g<1>{fmt(new_time)}", content)


def update_html_timing(html_path, cumulative_times, total_duration):
    """
    Rewrite clip timing and GSAP triggers to match actual TTS durations.

    cumulative_times = [0, d1, d1+d2, ..., total_speech]
    Layout is inferred from len(cumulative_times) - 1 (number of sections).

    Section roles by count:
      3 sections : hook | scard-content | cta
      4 sections : hook | r1 | r2 | cta
      5 sections : hook | r1 | r2 | r3 | cta
    """
    n = len(cumulative_times) - 1  # number of sections

    t_hook = cumulative_times[1]          # hook speech ends
    t_cta = cumulative_times[n - 1]       # CTA speech starts (= meat section ends)

    hook_dur = fmt(t_hook)
    meat_start = fmt(t_hook)
    meat_dur = fmt(t_cta - t_hook)
    cta_start = fmt(t_cta)
    cta_dur = fmt(CTA_DURATION)

    with open(html_path, encoding="utf-8") as f:
        content = f.read()

    # -- video + audio total duration --
    for ident in ['id="stage"', 'id="vo"', 'id="music"']:
        content = update_element_attr(content, ident, "data-duration", fmt(total_duration))

    # -- clip timing --
    for ident in ['id="bg-hook"', 'class="hook-wrap clip"']:
        content = update_element_attr(content, ident, "data-start", "0")
        content = update_element_attr(content, ident, "data-duration", hook_dur)

    # Meat-phase elements: all card types + headline share the same window
    for ident in [
        'id="bg-meat"', 'class="meat-hd clip"', 'class="scard clip"',
        'id="r1"', 'id="r2"', 'id="r3"',
    ]:
        content = update_element_attr(content, ident, "data-start", meat_start)
        content = update_element_attr(content, ident, "data-duration", meat_dur)

    for ident in ['id="bg-cta"', 'class="cta-wrap clip"']:
        content = update_element_attr(content, ident, "data-start", cta_start)
        content = update_element_attr(content, ident, "data-duration", cta_dur)

    # -- GSAP triggers --
    # meat headline (3-card and 2-card layouts)
    content = update_gsap(content, ".meat-hd", t_hook + 0.4)
    # single scard (3-section layout)
    content = update_gsap(content, ".scard", t_hook + 0.5)
    # r-cards: each reveals at the start of its own section
    content = update_gsap(content, "#r1", cumulative_times[1] + 0.5)
    if n >= 4:
        content = update_gsap(content, "#r2", cumulative_times[2] + 0.2)
    if n >= 5:
        content = update_gsap(content, "#r3", cumulative_times[3] + 0.2)
    # CTA
    content = update_gsap(content, ".cta-wrap", t_cta + 0.2)

    with open(html_path, "w", encoding="utf-8") as f:
        f.write(content)

    parts = [f"hook=0-{t_hook:.1f}s"]
    if n == 3:
        parts.append(f"scard={t_hook:.1f}-{t_cta:.1f}s")
    elif n == 4:
        parts.append(f"r1={t_hook:.1f}-{cumulative_times[2]:.1f}s")
        parts.append(f"r2={cumulative_times[2]:.1f}-{t_cta:.1f}s")
    elif n == 5:
        parts.append(f"r1={t_hook:.1f}-{cumulative_times[2]:.1f}s")
        parts.append(f"r2={cumulative_times[2]:.1f}-{cumulative_times[3]:.1f}s")
        parts.append(f"r3={cumulative_times[3]:.1f}-{t_cta:.1f}s")
    parts.append(f"cta={t_cta:.1f}-30s")
    print(f"  HTML: {' | '.join(parts)}")


# ── main per-ad processing ────────────────────────────────────────────────────

def process_ad(ad_dir):
    script_path = os.path.join(ad_dir, "voiceover-script.txt")
    out_path = os.path.join(ad_dir, "assets", "voiceover.mp3")
    html_path = os.path.join(ad_dir, "index.html")

    if not os.path.exists(script_path):
        print("  No voiceover script -- skipped")
        return False

    sections = parse_sections(script_path)
    n = len(sections)
    if n < 3:
        print(f"  Expected 3+ sections, got {n} -- skipped")
        return False

    os.makedirs(os.path.join(ad_dir, "assets"), exist_ok=True)
    tmpdir = tempfile.mkdtemp()

    try:
        section_files = []
        section_durs = []

        for i, (start, end, text) in enumerate(sections):
            preview = text[:50] + ("..." if len(text) > 50 else "")
            print(f"    [{i+1}/{n}] {preview}")

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

        total_speech = cumulative_times[-1]
        t_hook = cumulative_times[1]
        t_cta = cumulative_times[n - 1]
        total_duration = round(t_cta + CTA_DURATION, 2)
        print(f"  Speech: {total_speech:.1f}s | hook={t_hook:.1f}s cta={t_cta:.1f}s total={total_duration}s")

        # Concatenate all sections (no padding between)
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

        # Pad with trailing silence to fill exactly t_cta + CTA_DURATION
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

        # Update HTML timing
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
