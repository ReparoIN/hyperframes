# Useful queries for iterating ad copy

```bash
# Open the DB
sqlite3 ads.db

# All hooks by awareness level
SELECT id, awareness_level, text FROM hooks ORDER BY awareness_level, id;

# All draft hooks
SELECT id, text FROM hooks WHERE status = 'draft';

# Mark a hook as approved
UPDATE hooks SET status = 'approved' WHERE id = 3;

# Add a note to a hook
UPDATE hooks SET notes = 'needs Hinglish variant' WHERE id = 7;

# All approved hooks
SELECT id, awareness_level, text FROM hooks WHERE status = 'approved';

# Plan an ad combination
INSERT INTO ad_combinations (hook_id, meat_id, cta_id) VALUES (1, 3, 2);

# View all planned combinations with text
SELECT
  ac.id,
  h.awareness_level,
  h.text         AS hook,
  m.format       AS meat_format,
  m.title        AS meat_title,
  c.text         AS cta,
  ac.status
FROM ad_combinations ac
JOIN hooks h ON h.id = ac.hook_id
JOIN meats m ON m.id = ac.meat_id
JOIN ctas  c ON c.id  = ac.cta_id;

# Count by status
SELECT status, COUNT(*) FROM ad_combinations GROUP BY status;
```
