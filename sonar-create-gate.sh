#!/usr/bin/env bash
# SonarQube'da techstore-gate Quality Gate'i oluşturup projeye atar.
# Kullanım: SONAR_USER=admin SONAR_PASS=... bash sonar-create-gate.sh

set -euo pipefail
SONAR_HOST="${SONAR_HOST:-http://localhost:9000}"
SONAR_USER="${SONAR_USER:?SONAR_USER set edilmeli}"
SONAR_PASS="${SONAR_PASS:?SONAR_PASS set edilmeli}"
AUTH=(-u "$SONAR_USER:$SONAR_PASS")
PROJECT_KEY="techstore"
GATE_NAME="techstore-gate"

# 1. Gate oluştur
GATE_ID=$(curl -s "${AUTH[@]}" -X POST \
  "$SONAR_HOST/api/qualitygates/create?name=$GATE_NAME" \
  | python -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Created gate id=$GATE_ID name=$GATE_NAME"

# 2. Koşullar (overall code üzerinde)
add_cond() {
  curl -s "${AUTH[@]}" -X POST \
    "$SONAR_HOST/api/qualitygates/create_condition?gateId=$GATE_ID&metric=$1&op=$2&error=$3" >/dev/null
  echo "  + condition: $1 $2 $3"
}
add_cond coverage LT 80
add_cond duplicated_lines_density GT 5
add_cond reliability_rating GT 2      # 1=A 2=B; B'den kotuye gecince fail
add_cond sqale_rating GT 1            # Maintainability A'dan kotuye gecince fail

# 3. Projeye ata
curl -s "${AUTH[@]}" -X POST \
  "$SONAR_HOST/api/qualitygates/select?projectKey=$PROJECT_KEY&gateName=$GATE_NAME" >/dev/null
echo "Assigned gate '$GATE_NAME' to project '$PROJECT_KEY'"
