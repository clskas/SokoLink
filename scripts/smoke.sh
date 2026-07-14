#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${SMOKE_BASE_URL:-http://127.0.0.1:3100/v1}"

echo "== Smoke production-like checks against $BASE_URL =="
curl -fsS "$BASE_URL/health" | grep -q '"status":"ok"'
curl -fsS "$BASE_URL/categories" | grep -q 'name'
curl -fsS "$BASE_URL/provinces" | grep -q 'Kinshasa'
echo "Smoke OK"
