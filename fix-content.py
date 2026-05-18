import glob, re

# ── EDU voiceover scripts ─────────────────────────────────────────────────
for f in sorted(glob.glob('callcards-edu-ads/ad-*/voiceover-script.txt')):
    c = open(f, encoding='utf-8').read()
    c = c.replace(
        'Call Cards sends the follow-up the moment they scan your card.',
        'Call Cards logs every lead instantly — export to your CRM in one click, ready to follow up the same day.'
    )
    open(f, 'w', encoding='utf-8').write(c)
    print(f'  VO edu: {f}')

# ── EDU HTML files ────────────────────────────────────────────────────────
for f in sorted(glob.glob('callcards-edu-ads/ad-*/index.html')):
    c = open(f, encoding='utf-8').read()
    c = c.replace(
        'Follow-up sends the moment<br>they scan your card.',
        'Every lead exported instantly —<br>ready for your CRM in one click.'
    )
    open(f, 'w', encoding='utf-8').write(c)
    print(f'  HTML edu: {f}')

# ── DEMO voiceover scripts ────────────────────────────────────────────────
for f in sorted(glob.glob('callcards-demo-ads/ad-*/voiceover-script.txt')):
    c = open(f, encoding='utf-8').read()
    c = c.replace(
        'Step three: the follow-up sends itself. A pre-written message goes the moment they scan. No typing. Ever.',
        'Step three: they share their card back. One tap from their phone sends their contact straight to your dashboard. No asking. No typing.'
    )
    open(f, 'w', encoding='utf-8').write(c)
    print(f'  VO demo: {f}')

# ── DEMO HTML files ───────────────────────────────────────────────────────
NEW_DCARD = '''  <div class="dcard">
    <div class="dc-avatar"></div>
    <div class="dc-name">Rahul Sharma</div>
    <div class="dc-title">Sharma Exports · Buyer</div>
    <div class="dc-chips">
      <span class="chip chip-d">+91 98765 43210</span>
      <span class="chip chip-d">rahul@sharma.in</span>
    </div>
  </div>
  <div class="dcard-cap">Their contact. Your dashboard.</div>'''

NEW_ANIM = "tl.from('#d3 .dcard',{y:20,duration:0.45,ease:'power2.out'},18.3);"

for f in sorted(glob.glob('callcards-demo-ads/ad-*/index.html')):
    c = open(f, encoding='utf-8').read()

    # slabel + comment
    c = c.replace('Step 3 — Follow-up Sends Itself', 'Step 3 — They Share Back')
    c = c.replace('<!-- Step 3: Follow-up 18-24s -->', '<!-- Step 3: Share back 18-24s -->')

    # replace entire inner block (chat-area + chat-cap) with dcard
    c = re.sub(
        r'  <div class="chat-area">.*?</div>\s*\n  <div class="chat-cap">No typing\. Ever\.</div>',
        NEW_DCARD,
        c,
        flags=re.DOTALL
    )

    # GSAP animation line
    c = re.sub(
        r"tl\.from\('#d3 \.chat-bubble',\{x:20,duration:0\.45,ease:'power2\.out'\},18\.3\);",
        NEW_ANIM,
        c
    )

    open(f, 'w', encoding='utf-8').write(c)
    print(f'  HTML demo: {f}')

print('\nDone.')
