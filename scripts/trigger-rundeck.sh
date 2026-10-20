#!/usr/bin/env bash
# ==============================================================================
# Helper Script: Trigger Rundeck Deployment via REST API
# Use this to verify Jenkins -> Rundeck API integration independently
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

RUNDECK_HOST="${RUNDECK_HOST:-http://localhost:4440}"
RUNDECK_TOKEN="${RUNDECK_TOKEN:-}"
RUNDECK_JOB_UUID="${RUNDECK_JOB_UUID:-7b8e5c12-3456-4789-a1b2-c3d4e5f60002}"
BUILD_NUMBER="${1:-101}"
ARTIFACT_NAME="${2:-devops-demo-app-1.0.0.jar}"
ENVIRONMENT="${3:-production}"

if [ -z "$RUNDECK_TOKEN" ]; then
    echo -e "${RED}ERROR: RUNDECK_TOKEN environment variable is not set!${NC}"
    echo "Usage: RUNDECK_HOST=http://<ip>:4440 RUNDECK_TOKEN=<token> ./scripts/trigger-rundeck.sh [build_num] [artifact] [env]"
    exit 1
fi

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}       TRIGGERING RUNDECK DEPLOYMENT JOB VIA REST API                 ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo "Rundeck Host : ${RUNDECK_HOST}"
echo "Job UUID     : ${RUNDECK_JOB_UUID}"
echo "Build Number : #${BUILD_NUMBER}"
echo "Artifact     : ${ARTIFACT_NAME}"
echo "Environment  : ${ENVIRONMENT}"
echo ""

API_ENDPOINT="${RUNDECK_HOST}/api/45/job/${RUNDECK_JOB_UUID}/run"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "X-Rundeck-Auth-Token: ${RUNDECK_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
        \"options\": {
            \"BUILD_NUMBER\": \"${BUILD_NUMBER}\",
            \"ARTIFACT_NAME\": \"${ARTIFACT_NAME}\",
            \"ENVIRONMENT\": \"${ENVIRONMENT}\"
        }
    }" \
    "${API_ENDPOINT}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Response Status: ${HTTP_CODE}"
echo "Response Body:"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo -e "\n${GREEN}✓ SUCCESS: Rundeck execution started successfully!${NC}"
    EXEC_ID=$(echo "$BODY" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2 || echo "N/A")
    echo -e "Execution ID: ${EXEC_ID}"
    echo -e "Execution URL: ${RUNDECK_HOST}/project/DevOps-Automation/execution/show/${EXEC_ID}"
    exit 0
else
    echo -e "\n${RED}✗ ERROR: Failed to trigger Rundeck job (HTTP ${HTTP_CODE}).${NC}"
    exit 1
fi
