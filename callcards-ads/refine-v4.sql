-- Refinement Pass v4 — Final Check
-- Issues addressed:
--   1. #39 still had 'rupee' — stripped
--   2. #1 and #17 were near-identical questions — #17 rewritten to new angle
--   3. #8 and #9 overlapped — #8 rewritten to new angle
--   4. #6 used 'pipeline' jargon — changed to 'business'
--   5. #30 'across the country' was India-implicit — globalised
--   6. #42 rhythm — added 'same booth, same visitors' for test credibility
--   7. Meat 4 title still had ₹2L — fixed
--   8. India-specific and WhatsApp-specific items flagged in notes
-- Run after refine-v3.sql: sqlite3 ads.db < refine-v4.sql

PRAGMA foreign_keys = ON;

-- ─────────────────────────────────────────
-- HOOK FIXES
-- ─────────────────────────────────────────

-- #6: 'pipeline' is sales jargon. Swap to 'business'.
UPDATE hooks SET
  text  = 'Every expo, you leave business on the floor. You just can''t see exactly how much.',
  notes = 'v4: swapped "pipeline" (jargon) for "business" (universal). Loss aversion intact.'
WHERE id=6;

-- #8: Was near-duplicate of #9 (both = "most cards never get followed up").
-- New angle: a business card is a broken promise.
UPDATE hooks SET
  text  = 'A business card is a promise to follow up. Most exhibitors never keep it.',
  notes = 'v4: differentiated from #9. New angle: the card as a broken commitment. Regret aversion + mild guilt. No overlap with #9.'
WHERE id=8;

-- #17: Was near-duplicate of #1 (both = "how many did you follow up?").
-- New angle: the physical stack on the desk as a symbol of unfinished work.
UPDATE hooks SET
  text  = 'Somewhere in your office is a bag of cards from your last expo. Some of those were future customers.',
  notes = 'v4: differentiated from #1. Zeigarnik effect — the unfinished task is physically present in their space. Loss aversion (future customers already lost).'
WHERE id=17;

-- #30: 'across the country' reads as India. Globalised.
UPDATE hooks SET
  text  = 'Exhibitors everywhere are dropping paper cards. Here''s what they switched to.',
  notes = 'v4: removed "across the country" (India-implicit). Global-friendly. Social proof + curiosity gap intact.'
WHERE id=30;

-- #39: Still had 'rupee'. Stripped. Opportunity cost angle preserved.
UPDATE hooks SET
  text  = 'The money you spend printing cards could be spent closing them.',
  notes = 'v4: stripped "rupee" — slipped through v1–v3. Opportunity cost principle intact. No currency. Tighter sentence.'
WHERE id=39;

-- #42: 'at the same expo' felt thin for a test claim.
-- Added 'same booth, same visitors' to make the comparison feel rigorous.
UPDATE hooks SET
  text  = 'We tested paper cards against Call Cards at the same show. Same booth. Same visitors. It wasn''t close.',
  notes = 'v4: added "Same booth. Same visitors." The parallel structure makes the test feel fair and credible without inventing numbers.'
WHERE id=42;

-- ─────────────────────────────────────────
-- FLAG: India-specific and WhatsApp-specific hooks
-- These are strong for the Indian market. For global variants,
-- swap WhatsApp → 'direct message', remove geographic references.
-- ─────────────────────────────────────────

UPDATE hooks SET notes = 'INDIA/WHATSAPP-SPECIFIC. ' || notes WHERE id=5;
UPDATE hooks SET notes = 'INDIA/WHATSAPP-SPECIFIC. ' || notes WHERE id=14;
UPDATE hooks SET notes = 'INDIA-SPECIFIC (Indian trade shows). Global variant: remove geographic qualifier.' WHERE id=21;
UPDATE hooks SET notes = 'INDIA-SPECIFIC (identity + price). Strong for India. For global, rework without national identity angle.' WHERE id=25;
UPDATE hooks SET notes = 'INDIA/WHATSAPP-SPECIFIC. ' || notes WHERE id=28;
UPDATE hooks SET notes = 'INDIA-SPECIFIC (Indian trade show badges). Global variant: "Scan any trade show badge."' WHERE id=32;

-- ─────────────────────────────────────────
-- MEAT FIXES
-- ─────────────────────────────────────────

-- Meat 4: title still had ₹2L from original seed. Fixed.
UPDATE meats SET
  title = 'We Were Losing Leads at Every Expo',
  notes = 'v4: stripped ₹2L from title. Story arc unchanged.'
WHERE id=4;

-- Flag India-specific and WhatsApp-specific meats
UPDATE meats SET notes = 'INDIA/WHATSAPP-SPECIFIC: WhatsApp mentioned in Reason 2 and solution. For global: replace with "instant message" or "automated follow-up". ' || COALESCE(notes,'') WHERE id=3;
UPDATE meats SET notes = 'INDIA-SPECIFIC: references India ITME. For global variant, swap expo name or make generic ("our biggest show of the year"). ' || COALESCE(notes,'') WHERE id=4;
UPDATE meats SET notes = 'INDIA-SPECIFIC: Screen 1 says "Indian trade show badge". For global: "any trade show badge". ' || COALESCE(notes,'') WHERE id=5;

-- CTA 3: flag as WhatsApp-specific
UPDATE ctas SET notes = 'WHATSAPP-SPECIFIC. High intent for India and most global markets. For North America, swap to email or web form CTA.' WHERE id=3;

-- ─────────────────────────────────────────
-- FINAL VERIFICATION QUERIES
-- ─────────────────────────────────────────
--
-- No rupee signs anywhere:
--   SELECT 'hooks' AS tbl, id, text FROM hooks WHERE text LIKE '%₹%'
--   UNION ALL
--   SELECT 'meats', id, title FROM meats WHERE title LIKE '%₹%'
--   UNION ALL
--   SELECT 'meats', id, script FROM meats WHERE script LIKE '%₹%';
--
-- No raw percentages anywhere:
--   SELECT id, text FROM hooks WHERE text LIKE '%\%%' ESCAPE '\';
--
-- Hook status summary:
--   SELECT status, COUNT(*) FROM hooks GROUP BY status;
--
-- India-specific items (for when you build the global variant set):
--   SELECT id, awareness_level, text FROM hooks WHERE notes LIKE 'INDIA%';
--
-- Clean global hooks (no India/WhatsApp flag):
--   SELECT id, awareness_level, text FROM hooks
--   WHERE status IN ('approved','refined')
--   AND notes NOT LIKE 'INDIA%'
--   AND notes NOT LIKE 'WHATSAPP%'
--   ORDER BY awareness_level;
