-- Refinement Pass v3
-- Strip the unverified 72% stat from hooks #1 and #9.
-- Rule: no statistic in ad copy unless it is sourced and verifiable.
-- Emotional truth of the same idea is preserved without the number.
-- Run after refine-v2.sql: sqlite3 ads.db < refine-v3.sql

PRAGMA foreign_keys = ON;

-- #1: "72% of tradeshow leads are never followed up on."
-- The behaviour is true. The number is not verified.
UPDATE hooks SET
  text  = 'The leads you collected at your last expo. How many did you actually follow up on?',
  notes = 'v3: stripped unverified 72% stat. Rewritten as a direct question — exhibitor answers it themselves and feels the gap. Regret aversion + Zeigarnik open loop.'
WHERE id=1;

-- #9: "72% of tradeshow leads are never followed up on. Most of them were yours."
-- Same stat, same problem.
UPDATE hooks SET
  text  = 'Most exhibitors leave an expo with a pile of leads they''ll never contact. You already know if that''s you.',
  notes = 'v3: stripped unverified 72% stat. "You already know if that''s you" turns the mirror on the viewer — confirmation bias working for us, not against us.'
WHERE id=9;

-- VERIFICATION
-- No hooks should contain a percentage after this pass:
--   SELECT id, text FROM hooks WHERE text LIKE '%\%%' ESCAPE '\';
