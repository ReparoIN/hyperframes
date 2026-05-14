#!/usr/bin/env bash
# Creates ads.db from seed.sql
# Usage: ./init-db.sh
# Requires: sqlite3

set -e

DB=ads.db

if [ -f "$DB" ]; then
  echo "$DB already exists. Delete it first if you want to reseed."
  exit 1
fi

sqlite3 "$DB" < seed.sql
echo "Created $DB"
echo ""
sqlite3 "$DB" "SELECT awareness_level, COUNT(*) as count FROM hooks GROUP BY awareness_level;"
echo ""
sqlite3 "$DB" "SELECT format, title FROM meats;"
echo ""
sqlite3 "$DB" "SELECT type, text FROM ctas;"
