#!/usr/bin/env bash
# ==============================================================================
# Application Health Check Script
# Purpose: Health validation for Rundeck Operational Job 3
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

TARGET_HOST="${1:-${RD_OPTION_TARGET_HOST:-localhost}}"
TARGET_PORT="${2:-${RD_OPTION_TARGET_PORT:-8080}}"
BASE_URL="http://${TARGET_HOST}:${TARGET_PORT}"

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}              APPLICATION HEALTH CHECK REPORT                         ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "Target Endpoint : ${BASE_URL}"
echo -e "Execution Time  : $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo ""

# ------------------------------------------------------------------------------
# 1. Root Service Endpoint Verification
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Check 1/2] Verifying Root Status Endpoint (${BASE_URL}/)...${NC}"
ROOT_START=$(date +%s%N)
ROOT_RESPONSE=$(curl -s -w "\n%{http_code}" "${BASE_URL}/" || echo "000")
ROOT_END=$(date +%s%N)
ROOT_LATENCY=$(( (ROOT_END - ROOT_START) / 1000000 ))

ROOT_CODE=$(echo "$ROOT_RESPONSE" | tail -n1)
ROOT_BODY=$(echo "$ROOT_RESPONSE" | sed '$d')

echo -e "HTTP Response Code: ${ROOT_CODE}"
echo -e "Response Latency  : ${ROOT_LATENCY} ms"

if [ "$ROOT_CODE" -eq 200 ]; then
    echo -e "Payload Content   : ${ROOT_BODY}"
    echo -e "${GREEN}✓ Root endpoint responded successfully.${NC}"
else
    echo -e "${RED}✗ Root endpoint check failed with HTTP code ${ROOT_CODE}.${NC}"
    exit 1
fi

# ------------------------------------------------------------------------------
# 2. Detailed Health & Component Verification
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[Check 2/2] Verifying Health & Components (${BASE_URL}/api/health)...${NC}"
HEALTH_START=$(date +%s%N)
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "${BASE_URL}/api/health" || echo "000")
HEALTH_END=$(date +%s%N)
HEALTH_LATENCY=$(( (HEALTH_END - HEALTH_START) / 1000000 ))

HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

echo -e "HTTP Response Code: ${HEALTH_CODE}"
echo -e "Response Latency  : ${HEALTH_LATENCY} ms"
echo -e "Health Details    : ${HEALTH_BODY}"

if [ "$HEALTH_CODE" -eq 200 ]; then
    STATUS=$(echo "$HEALTH_BODY" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "")
    if [ "$STATUS" = "HEALTHY" ]; then
        echo -e "\n${CYAN}======================================================================${NC}"
        echo -e "${GREEN}✓ RESULT: APPLICATION STATUS IS HEALTHY (All checks passed)${NC}"
        echo -e "${CYAN}======================================================================${NC}"
        exit 0
    else
        echo -e "\n${RED}✗ RESULT: APPLICATION UNHEALTHY (Status: ${STATUS})${NC}"
        exit 1
    fi
else
    echo -e "\n${RED}======================================================================${NC}"
    echo -e "${RED}✗ RESULT: HEALTH ENDPOINT RETURNED ERROR (HTTP ${HEALTH_CODE})${NC}"
    echo -e "${RED}======================================================================${NC}"
    exit 1
fi
