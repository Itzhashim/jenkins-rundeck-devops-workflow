#!/usr/bin/env bash
# ==============================================================================
# Automated Application Deployment Script
# Executed by Rundeck Job 2 (Application Deployment)
# Features:
#   1. Zero-downtime symlink deployment
#   2. Automatic backup of previous release
#   3. Systemd service restart
#   4. Post-deploy health polling
#   5. Automated rollback on startup or health failure
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}              APPLICATION DEPLOYMENT WORKFLOW                         ${NC}"
echo -e "${CYAN}======================================================================${NC}"

# Parameters (can be passed via CLI or Rundeck options)
BUILD_NUMBER="${1:-${RD_OPTION_BUILD_NUMBER:-manual}}"
ARTIFACT_NAME="${2:-${RD_OPTION_ARTIFACT_NAME:-devops-demo-app-1.0.0.jar}}"
ENVIRONMENT="${3:-${RD_OPTION_ENVIRONMENT:-production}}"

APP_DIR="/opt/devops-app"
RELEASES_DIR="${APP_DIR}/releases"
BACKUPS_DIR="${APP_DIR}/backups"
CURRENT_DIR="${APP_DIR}/current"
STAGING_DIR="/tmp/devops-artifacts"

echo -e "Target Environment : ${ENVIRONMENT}"
echo -e "Build Identifier   : #${BUILD_NUMBER}"
echo -e "Artifact Name      : ${ARTIFACT_NAME}"
echo -e "Deployment Time    : $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo ""

# Ensure required directories exist with proper permissions
echo -e "${BOLD}[Step 1/5] Preparing deployment directory structure...${NC}"
sudo mkdir -p "${RELEASES_DIR}" "${BACKUPS_DIR}" "${CURRENT_DIR}"
sudo chown -R devops:devops "${APP_DIR}" 2>/dev/null || true

# Check for new artifact in releases directory or staging directory
NEW_ARTIFACT=""
if [ -f "${RELEASES_DIR}/${ARTIFACT_NAME}" ]; then
    NEW_ARTIFACT="${RELEASES_DIR}/${ARTIFACT_NAME}"
elif [ -f "${STAGING_DIR}/${ARTIFACT_NAME}" ]; then
    echo -e "Moving artifact from staging directory ${STAGING_DIR} to ${RELEASES_DIR}..."
    sudo cp "${STAGING_DIR}/${ARTIFACT_NAME}" "${RELEASES_DIR}/${ARTIFACT_NAME}"
    NEW_ARTIFACT="${RELEASES_DIR}/${ARTIFACT_NAME}"
elif [ -f "./target/${ARTIFACT_NAME}" ]; then
    echo -e "Local build detected; copying from ./target..."
    sudo cp "./target/${ARTIFACT_NAME}" "${RELEASES_DIR}/${ARTIFACT_NAME}"
    NEW_ARTIFACT="${RELEASES_DIR}/${ARTIFACT_NAME}"
else
    echo -e "${RED}ERROR: Artifact ${ARTIFACT_NAME} not found in ${RELEASES_DIR} or ${STAGING_DIR}.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Verified artifact:${NC} ${NEW_ARTIFACT}"

# Backup current active JAR if present
echo -e "\n${BOLD}[Step 2/5] Creating backup of current release...${NC}"
PREV_JAR="${CURRENT_DIR}/devops-demo-app.jar"
BACKUP_JAR="${BACKUPS_DIR}/devops-demo-app-pre-build-${BUILD_NUMBER}-$(date +%s).jar"

if [ -f "${PREV_JAR}" ]; then
    echo -e "Backing up existing JAR to ${BACKUP_JAR}..."
    sudo cp "${PREV_JAR}" "${BACKUP_JAR}"
    echo -e "${GREEN}✓ Backup created successfully.${NC}"
else
    echo -e "${YELLOW}! No existing active JAR found. Initial release.${NC}"
fi

# Deploy new release and update symlink
echo -e "\n${BOLD}[Step 3/5] Deploying new release and updating symlink...${NC}"
BUILD_SPECIFIC_JAR="${RELEASES_DIR}/devops-demo-app-build-${BUILD_NUMBER}.jar"
sudo cp "${NEW_ARTIFACT}" "${BUILD_SPECIFIC_JAR}"
sudo ln -sf "${BUILD_SPECIFIC_JAR}" "${CURRENT_DIR}/devops-demo-app.jar"
sudo chown -R devops:devops "${APP_DIR}" 2>/dev/null || true
echo -e "${GREEN}✓ Active JAR linked to build #${BUILD_NUMBER}${NC}"

# Restart the application service via systemd
echo -e "\n${BOLD}[Step 4/5] Restarting application service via systemd...${NC}"
if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q "devops-app.service"; then
    echo "Reloading systemd daemon and restarting devops-app.service..."
    sudo systemctl daemon-reload
    sudo systemctl restart devops-app
else
    echo -e "${YELLOW}systemd unit not found. Starting directly via background Java process for demo...${NC}"
    # Fallback for systems without systemd service configured yet
    sudo pkill -f "devops-demo-app" || true
    sleep 2
    nohup java -jar "${CURRENT_DIR}/devops-demo-app.jar" > "${APP_DIR}/app.log" 2>&1 &
fi
echo -e "${GREEN}✓ Application restart initiated.${NC}"

# Health check verification & Auto-rollback logic
echo -e "\n${BOLD}[Step 5/5] Polling application health endpoint for startup verification...${NC}"
HEALTH_URL="http://localhost:8080/api/health"
MAX_ATTEMPTS=15
ATTEMPT=1
IS_HEALTHY=false

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo -e "Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: Checking ${HEALTH_URL}..."
    HTTP_RESPONSE=$(curl -s -o /tmp/health_resp.json -w "%{http_code}" "${HEALTH_URL}" || echo "000")

    if [ "$HTTP_RESPONSE" -eq 200 ]; then
        STATUS_VALUE=$(grep -o '"status":"[^"]*"' /tmp/health_resp.json | cut -d'"' -f4 || echo "")
        if [ "$STATUS_VALUE" = "HEALTHY" ]; then
            IS_HEALTHY=true
            break
        fi
    fi

    sleep 3
    ATTEMPT=$((ATTEMPT + 1))
done

if [ "$IS_HEALTHY" = true ]; then
    echo -e "\n${GREEN}======================================================================${NC}"
    echo -e "${GREEN}✓ DEPLOYMENT SUCCESSFUL: Application is UP and HEALTHY!${NC}"
    cat /tmp/health_resp.json | python3 -m json.tool 2>/dev/null || cat /tmp/health_resp.json
    echo -e "\n${GREEN}======================================================================${NC}"
    exit 0
else
    echo -e "\n${RED}======================================================================${NC}"
    echo -e "${RED}✗ DEPLOYMENT FAILED: Health check failed after ${MAX_ATTEMPTS} attempts!${NC}"
    echo -e "${RED}Initiating automated rollback to previous release...${NC}"
    
    if [ -f "${BACKUP_JAR}" ]; then
        echo -e "Restoring backup JAR: ${BACKUP_JAR}..."
        sudo cp "${BACKUP_JAR}" "${CURRENT_DIR}/devops-demo-app.jar"
        if command -v systemctl >/dev/null 2>&1; then
            sudo systemctl restart devops-app
        fi
        echo -e "${YELLOW}Rollback completed. Restored previous stable version.${NC}"
    else
        echo -e "${RED}No previous backup available for rollback.${NC}"
    fi
    echo -e "${RED}======================================================================${NC}"
    exit 1
fi
