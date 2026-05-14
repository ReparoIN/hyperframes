# Video

Plan and produce marketing videos using programmatic frameworks, AI generation, and avatars — from product demos to batch social ads.

## Before Starting

1. **Video Goal** — type (demo, explainer, testimonial, social ad), target platform, desired length
2. **Production Approach** — human presenter needed? existing footage? AI generation? template vs. one-off?
3. **Technical Context** — tech stack, available API keys, budget

## Choosing Your Approach

| Approach | Best For | Tools |
|----------|----------|-------|
| Programmatic | Batch ads, data-driven, agent-native | HyperFrames, Remotion |
| AI Generation | B-roll, creative visuals, no filming | Veo, Runway, Kling, Pika |
| AI Avatars | Talking head without filming | HeyGen (has MCP), Synthesia |
| Editing/Repurpose | Long-form → short clips | Descript, Opus Clip, CapCut |

## Programmatic Video

### HyperFrames (recommended for agents)
- Open-source, Apache 2.0
- HTML/CSS/JS — no framework DSL to learn
- LLM-native: agents read and write it directly
- Deterministic rendering — same input = same output every time
- Use for: social ads, explainers, animated copy, batch production

**HyperFrames rules:**
- Every timed element needs `class="clip"`, `data-start`, `data-duration`, `data-track-index`
- All animations via GSAP timelines: `gsap.timeline({ paused: true })`
- Register on `window.__timelines["composition-name"] = tl`
- No `Date.now()`, `Math.random()`, or network fetches inside compositions
- Aspect ratios: 1080×1920 (9:16 vertical) for social, 1920×1080 (16:9) for YouTube/website

### Remotion
- React component-based
- Lambda rendering for scale
- Company license required for commercial use
- Better for: complex data-driven animations, existing React codebases

**When to pick HyperFrames vs. Remotion:**
- Agent-written code → HyperFrames
- React team, complex data props → Remotion
- Batch social ads → HyperFrames
- Lambda scale rendering → Remotion

## AI Video Generation

| Model | Best For |
|-------|----------|
| Veo 3 (Google) | Realism, long duration |
| Runway Gen-4 | Creative control |
| Kling 3.0 | Cost-effective, Asian markets |
| Pika | Quick iterations |

**Prompting formula:** Subject + action + camera movement + style + mood

**When to use AI generation vs. stock:**
- Brand-specific scenario → AI generation
- Generic background/cutaway → stock
- Text in frame → neither (use programmatic overlay instead)

⚠️ AI models struggle to render legible text. Always use programmatic text overlays.

## AI Avatars

**HeyGen** (recommended — has MCP server for direct agent integration)
- 230+ avatars, 140+ languages
- Custom avatar: 2–5 minutes of source video required

**Synthesia**
- Full-body avatars
- Enterprise-focused

**When to use avatars:**
- Talking-head explainer without filming
- Multilingual versions of same script
- Scale (one script → many avatar variations)

## Editing & Repurposing Tools

| Tool | What It Does |
|------|--------------|
| Descript | Transcript-based editing, cleanup |
| Opus Clip | Auto-extract viral moments from long-form |
| CapCut | Styling, captions, platform export |
| Captions.ai | Auto-captions, reframing |

**Repurposing workflow:** Long-form → Descript cleanup → Opus Clip extraction → CapCut styling → distribute

## Production Workflows

### Product Demo
1. Script the flow (problem → feature → outcome)
2. Screen record or capture device footage
3. Add programmatic overlays via HyperFrames (callouts, captions, highlights)
4. Add AI B-roll for context shots
5. Add voiceover (TTS or recorded)
6. Export: 9:16 for social, 16:9 for website

### Explainer Video
1. Script arc: problem → solution → CTA
2. Choose presenter: human, avatar, or faceless
3. Build visuals: HyperFrames for motion graphics, AI for B-roll
4. Add captions (85% of social video watched without sound)
5. Export formats per platform

### Batch Social Ads (HyperFrames)
1. Build modular composition: hook scene + meat scene + CTA scene
2. Parameterize text/colors as variables
3. Feed hook/meat/CTA combinations from a data source (e.g., SQLite DB)
4. Batch render all combinations
5. Add platform-specific captions
6. Schedule and distribute

## Agent-Native Pipeline

1. Agent writes script from product context
2. Generate templated video via HyperFrames
3. Generate avatar video via HeyGen MCP (if talking head needed)
4. Generate B-roll via Veo/Runway API
5. Agent assembles final cut
6. Output: ready-to-publish video file

## Common Mistakes

1. Trying to render text inside AI-generated video (use overlays instead)
2. Not adding captions (85% of social video is watched muted)
3. Wrong aspect ratio per platform
4. No clear CTA in final 3 seconds
5. Over-animating — motion should support, not distract
6. Skipping mobile preview before publishing

## Platform Specs

| Platform | Ratio | Max Length | Notes |
|----------|-------|------------|-------|
| Instagram Feed | 1:1 or 4:5 | 60s | |
| Instagram Stories/Reels | 9:16 | 90s | |
| TikTok | 9:16 | 10 min | 15–60s performs best |
| LinkedIn Feed | 1:1 or 16:9 | 10 min | 30–90s performs best |
| YouTube | 16:9 | No limit | |
| YouTube Shorts | 9:16 | 60s | |

## Related Skills
- `ad-creative` — copy for video ads
- `copywriting` — scripts and on-screen text
- `marketing-psychology` — hook and structure psychology
- `social` — platform strategy and distribution
