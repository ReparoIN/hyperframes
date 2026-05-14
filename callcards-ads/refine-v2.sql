-- Refinement Pass v2
-- Strip all invented numbers. Keep emotional truth.
-- Only real stat kept: 72% of tradeshow leads never followed up (cited in strategy/marketing/video-tutorial.md)
-- Run after refine-v1.sql: sqlite3 ads.db < refine-v2.sql

PRAGMA foreign_keys = ON;

-- ─────────────────────────────────────────
-- HOOKS: remove invented numbers, preserve emotion
-- ─────────────────────────────────────────

-- #2: "You spent ₹3 lakhs on a booth. You lost 400 leads."
-- Booth cost varies wildly. Numbers invented. Keep the gut-punch.
UPDATE hooks SET
  text  = 'You spent a fortune on the booth. You lost the leads that were supposed to pay for it.',
  notes = 'v2: stripped invented ₹3L and 400 leads. Emotional truth preserved. Loss aversion intact.'
WHERE id=2;

-- #4: "The exhibitor next to you just captured 200 leads. You captured 12."
-- Comparison numbers invented. Keep the contrast and the sting.
UPDATE hooks SET
  text  = 'The exhibitor next to you walked away with a full lead list. You walked away with a bag of cards.',
  notes = 'v2: stripped invented numbers. Contrast effect and mimetic desire intact. "Bag of cards" is vivid.'
WHERE id=4;

-- #6: "The average Indian exhibitor leaves ₹50,000+ in unclosed pipeline..."
-- Rupee figure invented. Keep the loss without the number.
UPDATE hooks SET
  text  = 'Every expo, you leave pipeline on the floor. You just can''t see exactly how much.',
  notes = 'v2: stripped invented rupee figure. Loss aversion preserved. Ambiguity is honest and still creates unease.'
WHERE id=6;

-- #8: "The average exhibitor throws away 60% of collected cards."
-- 60% unverified. Rewrite to emotional truth.
UPDATE hooks SET
  text  = 'Most of the cards you collect at expos never turn into a conversation.',
  notes = 'v2: stripped unverified 60%. Kept the truth of the behaviour without a made-up stat.'
WHERE id=8;

-- #9: "India hosts 5,000+ trade shows every year. 72% of leads never followed up."
-- 72% is real (cited in strategy doc). Keep it. Strip the 5000+ if unverified.
UPDATE hooks SET
  text  = '72% of tradeshow leads are never followed up on. Most of them were yours.',
  notes = 'v2: 72% is a real cited stat — kept. Removed unverified 5000+ figure. Added "most of them were yours" for direct loss aversion.'
WHERE id=9;

-- #30: "1,000+ Indian exhibitors stopped printing business cards."
-- User count invented. Keep social proof without the number.
UPDATE hooks SET
  text  = 'Exhibitors across the country stopped printing business cards. Here''s what they use instead.',
  notes = 'v2: stripped invented 1000+ count. Social proof angle retained without unverifiable claim.'
WHERE id=30;

-- #37: "500 business cards cost ₹2,000. The leads they can''t capture cost you 50x more."
-- All figures invented. Keep the opportunity cost without the ratio.
UPDATE hooks SET
  text  = 'Business cards are the cheapest part of your expo. The leads they lose you aren''t.',
  notes = 'v2: stripped invented rupee figures and 50x ratio. Opportunity cost principle intact. Contrast is sharper without the fake math.'
WHERE id=37;

-- #41: "I scanned 300 badges in one day. Here''s how."
-- 300 invented. Keep the curiosity without the number.
UPDATE hooks SET
  text  = 'I scanned every badge that walked past my booth. Here''s how.',
  notes = 'v2: stripped invented 300. "Every badge" is bolder and more credible than a made-up count.'
WHERE id=41;

-- #42: "We ran paper cards vs. Call Cards at 3 Indian expos. Digital captured 8x more leads."
-- 3 expos and 8x both invented. Keep the test framing.
UPDATE hooks SET
  text  = 'We ran paper cards vs. Call Cards at the same expo. It wasn''t close.',
  notes = 'v2: stripped 3 expos and 8x multiplier. "It wasn''t close" implies the same without fabricating a ratio.'
WHERE id=42;

-- #44: "This QR code made an exhibitor ₹14 lakhs in pipeline."
-- Rupee figure invented. Keep the aspiration.
UPDATE hooks SET
  text  = 'This QR code built one exhibitor''s best quarter. Here''s what it does.',
  notes = 'v2: stripped invented ₹14L. "Best quarter" is aspirational and credible without a made-up figure.'
WHERE id=44;

-- #49: "I asked 50 Indian exhibitors how they follow up leads. Most had no answer."
-- 50 invented. Keep the research framing.
UPDATE hooks SET
  text  = 'I asked exhibitors how they follow up on leads after a show. Most had no real answer.',
  notes = 'v2: stripped invented 50. Research framing and social proof of the problem retained.'
WHERE id=49;

-- ─────────────────────────────────────────
-- MEATS: strip invented testimonial and demo numbers
-- ─────────────────────────────────────────

-- Meat 1 (Demo): strip "47 leads captured today"
UPDATE meats SET
  script = 'Open on close-up: phone camera moving toward QR code at a busy booth.
Card appears in under a second — exhibitor photo, company name, product catalog, WhatsApp button all visible.
Visitor taps WhatsApp. Pre-written follow-up message sends instantly — no typing.
Cut to exhibitor''s dashboard: a full list of leads from the day, each with name, company, phone number.
VO: "One scan. They get your full catalog. You get their contact. The follow-up sends itself."
End card: call.cards',
  notes = 'v2: replaced "47 leads captured today" with "a full list of leads from the day." Outcome is clear without an invented count.'
WHERE id=1;

-- Meat 2 (Testimonial): strip invented lead counts and deal numbers
UPDATE meats SET
  script = 'Exhibitor to camera, at booth or office:
"Before Call Cards, we''d come home from every expo with a bag full of cards. We''d follow up with a fraction of them — the rest just sat there.
Since switching, every lead we capture is complete. Name, company, WhatsApp number — all in one place.
Our team follows up the same day the show ends. We''ve closed deals from expos we would have written off before.
The difference isn''t the product. It''s that we actually follow up now."
End card: call.cards',
  notes = 'v2: stripped all invented numbers (340 leads, 12 deals, 24 hrs, 150-200 cards). Emotional truth kept: the shift from chaos to system. "The difference isn''t the product. It''s that we actually follow up now." is the real insight.'
WHERE id=2;

-- Meat 4 (Story): strip invented lead counts and deal numbers
UPDATE meats SET
  script = 'Founder or senior exhibitor to camera:

"Every expo we''d come back with cards stuffed in a bag. Wet from rain. Some misprinted. Half of them we had no context for.

Two weeks later, we''d try to follow up. But which contact was interested in which product? We''d lost the thread on most of them.

Before India ITME, we switched to Call Cards and turned on the badge scanner. Instead of collecting cards, we scanned visitor badges. Name, company, designation — all captured in one tap.

We left with every lead complete. We knew exactly who each person was, what they''d looked at in our catalog, when they''d visited our booth. We followed up the same day the show ended.

Best expo result we''d ever had."

End card: call.cards',
  notes = 'v2: stripped 410 leads and 12 deals. Kept the story arc and badge scanner as turning point. "Best expo result we''d ever had" is honest without a fabricated number.'
WHERE id=4;

-- ─────────────────────────────────────────
-- VERIFICATION
-- ─────────────────────────────────────────
-- Hooks still containing currency symbols (should return 0 rows after this pass):
--   SELECT id, text FROM hooks WHERE text LIKE ''%₹%'';
--
-- Hooks still containing raw numbers (review manually):
--   SELECT id, text FROM hooks WHERE text GLOB ''*[0-9]*'';
--   (72% in id=1 and id=9 are intentional — real cited stat)
