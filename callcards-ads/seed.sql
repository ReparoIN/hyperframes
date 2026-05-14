-- Call Cards Ad Copy Database
-- Hormozi framework: 50 hooks × 5 meats × 3 CTAs = up to 750 unique ads
-- Run: sqlite3 ads.db < seed.sql

PRAGMA foreign_keys = ON;

-- ─────────────────────────────────────────
-- SCHEMA
-- ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS hooks (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  text            TEXT    NOT NULL,
  awareness_level TEXT    NOT NULL, -- unaware | problem_aware | solution_aware | product_aware | competitor | pattern_interrupt
  status          TEXT    NOT NULL DEFAULT 'draft', -- draft | refined | approved | in_production | done
  notes           TEXT,
  created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS meats (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  format      TEXT    NOT NULL, -- demo | testimonial | educational | story | faceless
  title       TEXT    NOT NULL,
  description TEXT    NOT NULL,
  script      TEXT,
  status      TEXT    NOT NULL DEFAULT 'draft',
  notes       TEXT,
  created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ctas (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  text       TEXT    NOT NULL,
  type       TEXT    NOT NULL, -- soft | direct | whatsapp
  status     TEXT    NOT NULL DEFAULT 'draft',
  notes      TEXT,
  created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ad_combinations (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  hook_id    INTEGER NOT NULL REFERENCES hooks(id),
  meat_id    INTEGER NOT NULL REFERENCES meats(id),
  cta_id     INTEGER NOT NULL REFERENCES ctas(id),
  status     TEXT    NOT NULL DEFAULT 'planned', -- planned | scripted | filmed | edited | published
  notes      TEXT,
  created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ─────────────────────────────────────────
-- HOOKS — 50 total
-- ─────────────────────────────────────────

-- Unaware (10)
INSERT INTO hooks (text, awareness_level) VALUES
  ('72% of tradeshow leads are never followed up on.', 'unaware'),
  ('You spent ₹3 lakhs on a booth. You lost 400 leads.', 'unaware'),
  ('Your next customer is already forgetting your name.', 'unaware'),
  ('The exhibitor next to you just captured 200 leads. You captured 12.', 'unaware'),
  ('Paper cards don''t follow up. Your competition does.', 'unaware'),
  ('Every expo, Indian exhibitors lose crores in leads they never close.', 'unaware'),
  ('What happens to your business cards after the show ends?', 'unaware'),
  ('The average exhibitor throws away 60% of collected cards.', 'unaware'),
  ('India has 5,000+ trade shows a year. Most exhibitors leave empty-handed.', 'unaware'),
  ('You can''t close a lead you can''t remember.', 'unaware');

-- Problem Aware (10)
INSERT INTO hooks (text, awareness_level) VALUES
  ('Still giving out paper business cards in 2025?', 'problem_aware'),
  ('Paper cards get lost. Deals get lost with them.', 'problem_aware'),
  ('Your competitor switched to digital. You haven''t.', 'problem_aware'),
  ('Business cards end up in the bin. Digital cards end up in WhatsApp.', 'problem_aware'),
  ('Wet cards. Misprinted cards. Forgotten cards. There''s a better way.', 'problem_aware'),
  ('You ran out of cards on Day 1. That won''t happen again.', 'problem_aware'),
  ('How many cards did you collect at your last expo that you never contacted?', 'problem_aware'),
  ('Paper cards worked in 1999. This is what works now.', 'problem_aware'),
  ('Stop reprinting cards every time your number changes.', 'problem_aware'),
  ('Your card is in their pocket. Your competitor is in their phone.', 'problem_aware');

-- Solution Aware (10)
INSERT INTO hooks (text, awareness_level) VALUES
  ('Not all digital business cards work at Indian trade shows.', 'solution_aware'),
  ('Most digital card apps don''t have badge scanning. This one does.', 'solution_aware'),
  ('You''ve heard of digital cards. Here''s why Call Cards is different.', 'solution_aware'),
  ('A digital card that works even when there''s no internet at the expo.', 'solution_aware'),
  ('Built for Indian exhibitors. Not imported software with an Indian price tag.', 'solution_aware'),
  ('Other apps give you a card. This gives you a complete lead system.', 'solution_aware'),
  ('QR code cards are fine. Badge-scanning cards are better.', 'solution_aware'),
  ('If your digital card doesn''t connect to WhatsApp, it''s not doing its job.', 'solution_aware'),
  ('Most digital cards stop at the scan. Call Cards starts the follow-up.', 'solution_aware'),
  ('Here''s why 1,000+ Indian exhibitors switched to Call Cards.', 'solution_aware');

-- Product Aware (5)
INSERT INTO hooks (text, awareness_level) VALUES
  ('You''ve seen Call Cards. Here''s what it actually looks like in action.', 'product_aware'),
  ('Call Cards just added badge scanning for Indian trade show badges.', 'product_aware'),
  ('Three things Call Cards does that your current setup can''t.', 'product_aware'),
  ('This is what happens when an exhibitor uses Call Cards for 30 days.', 'product_aware'),
  ('Call Cards vs. paper: a side-by-side at the same expo booth.', 'product_aware');

-- Competitor / Reframe (5)
INSERT INTO hooks (text, awareness_level) VALUES
  ('Your print vendor gets paid whether you close leads or not. We don''t.', 'competitor'),
  ('The cost of 500 business cards: ₹2,000. The leads you lose: priceless.', 'competitor'),
  ('What if your marketing budget worked after the show, not just during it?', 'competitor'),
  ('Every rupee you spend on printing is a rupee you could spend on follow-up.', 'competitor'),
  ('Printers don''t track who scanned your card. We do.', 'competitor');

-- Pattern Interrupt (10)
INSERT INTO hooks (text, awareness_level) VALUES
  ('I scanned 300 badges in one day. Here''s how.', 'pattern_interrupt'),
  ('We tested paper cards vs. digital at 3 Indian expos. The results shocked us.', 'pattern_interrupt'),
  ('Watch this exhibitor close a lead in real time using their phone.', 'pattern_interrupt'),
  ('This QR code made an exhibitor ₹14 lakhs in pipeline.', 'pattern_interrupt'),
  ('The booth next to us had no cards. They still got more leads.', 'pattern_interrupt'),
  ('Delete your card designer app. You don''t need it anymore.', 'pattern_interrupt'),
  ('One scan. One second. Full lead captured. Let me show you.', 'pattern_interrupt'),
  ('Stop. Before your next trade show, watch this.', 'pattern_interrupt'),
  ('I asked 50 Indian exhibitors how they follow up leads. Most had no answer.', 'pattern_interrupt'),
  ('What if your business card could follow up for you while you sleep?', 'pattern_interrupt');

-- ─────────────────────────────────────────
-- MEATS — 5 formats
-- ─────────────────────────────────────────

INSERT INTO meats (format, title, description, script) VALUES
  (
    'demo',
    'QR Scan to WhatsApp in 60 Seconds',
    'Screen-capture walkthrough: visitor scans QR → digital card opens → taps WhatsApp → follow-up message sends. 30–45s.',
    'Show phone scanning QR at a booth. Card opens instantly. Visitor taps WhatsApp button. Pre-filled message sends. Exhibitor sees lead in dashboard. VO: "One scan. They have your card. You have their contact. Follow-up sent automatically."'
  ),
  (
    'testimonial',
    'Exhibitor at India ITME',
    'Real exhibitor to camera: collected X leads in Y days using Call Cards vs. previous method.',
    'Exhibitor: "We used to collect 80–100 cards at every show and follow up with maybe 10. At the last expo we captured 340 leads in Call Cards and our team followed up with all of them within 24 hours. Our pipeline tripled."'
  ),
  (
    'educational',
    '3 Reasons Paper Cards Fail at Trade Shows',
    'Text card + voiceover breakdown. Faceless-friendly. Works as carousel or single video.',
    'Reason 1: They get lost — in bags, pockets, dustbins. Reason 2: No follow-up system — you collect but never act. Reason 3: No data — you don''t know who scanned, when, or how many times. Call Cards solves all three.'
  ),
  (
    'story',
    'We Were Losing ₹2L in Leads Every Expo',
    'Founder or exhibitor-style talking head. Problem → turning point → result arc.',
    'Setup: "Every expo we''d come back with 200 cards stuffed in a bag." Conflict: "Two weeks later, half were unreadable. We''d lost the context for the rest." Turn: "We switched to Call Cards before India Pharma 2024." Resolution: "We left with 410 captured leads, every one with a name, company, and WhatsApp number. We closed 12 deals from that one show."'
  ),
  (
    'faceless',
    'App Walkthrough — Full Lead Flow',
    'Screen recording of the app: badge scan → catalog view → lead capture form → export to CRM. No face needed. Text overlays only.',
    'Screen 1: Badge scanner — tap, scan, lead captured. Screen 2: Digital catalog — swipe through products. Screen 3: Lead form — auto-filled from badge. Screen 4: Dashboard — all leads, exportable. Text overlay each step. End card: call.cards'
  );

-- ─────────────────────────────────────────
-- CTAs — 3
-- ─────────────────────────────────────────

INSERT INTO ctas (text, type) VALUES
  ('See yours in 60 seconds → call.cards', 'soft'),
  ('Get your free digital card at call.cards', 'direct'),
  ('DM us CARD on WhatsApp to get started free', 'whatsapp');
