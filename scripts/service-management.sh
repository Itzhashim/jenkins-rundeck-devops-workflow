#!/usr/bin/env bash
# ==============================================================================
# Service Management Script
# Purpose: Operational control for Rundeck Job 4 (Parameterized Service Management)
# Security: Strict whitelisting of services and actions to prevent command injection
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SERVICE_NAME="${1:-${RD_OPTION_SERVICE_NAME}}"
ACTION="${2:-${RD_OPTION_ACTION}}"

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}              RUNDECK SERVICE OPERATIONS MANAGER                      ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "Requested Service : ${SERVICE_NAME}"
echo -e "Requested Action  : ${ACTION}"
echo -e "Executed At       : $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo ""

# ------------------------------------------------------------------------------
# 1. Input Validation (Security Protection)
# ------------------------------------------------------------------------------
ALLOWED_SERVICES=("devops-app" "rundeckd" "jenkins" "ssh" "nginx")
ALLOWED_ACTIONS=("status" "start" "stop" "restart" "reload")

# Validate Action
ACTION_VALID=false
for A in "${ALLOWED_ACTIONS[@]}"; do
    if [ "$ACTION" = "$A" ]; then
        ACTION_VALID=true
        break
    fi
done

if [ "$ACTION_VALID" = false ]; then
    echo -e "${RED}SECURITY ERROR: Action '${ACTION}' is invalid or unauthorized.${NC}"
    echo -e "Permitted actions: ${ALLOWED_ACTIONS[*]}"
    exit 1
fi

# Validate Service
SERVICE_VALID=false
for S in "${ALLOWED_SERVICES[@]}"; do
    if [ "$SERVICE_NAME" = "$S" ]; then
        SERVICE_VALID=true
        break
    fi
done

if [ "$SERVICE_VALID" = false ]; then
    echo -e "${RED}SECURITY ERROR: Service '${SERVICE_NAME}' is not in the authorized service whitelist.${NC}"
    echo -e "Authorized services: ${ALLOWED_SERVICES[*]}"
    exit 1
fi

echo -e "${GREEN}✓ Security Check Passed: Service and Action are authorized.${NC}"

# ------------------------------------------------------------------------------
# 2. Execute Systemd Operation
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}Executing: systemctl ${ACTION} ${SERVICE_NAME}...${NC}\n"

if command -v systemctl >/dev/null 2>&1; then
    case "$ACTION" in
        status)
            sudo systemctl status "$SERVICE_NAME" --no-pager || true
            ;;
        start|stop|restart|reload)
            sudo systemctl "$ACTION" "$SERVICE_NAME"
            echo -e "${GREEN}✓ Successfully issued '${ACTION}' to '${SERVICE_NAME}'.${NC}\n"
            echo -e "Current service status:"
            sudo systemctl status "$SERVICE_NAME" --no-pager || true
            ;;
    esac
else
    echo -e "${YELLOW}systemctl not detected in environment. Running simulated operation for testing.${NC}"
    echo -e "[SIMULATION] Service '${SERVICE_NAME}' -> Action '${ACTION}' executed successfully."
fi

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${GREEN}Operation '${ACTION}' on '${SERVICE_NAME}' completed.${NC}"
echo -e "${CYAN}======================================================================${NC}"
exit 0
