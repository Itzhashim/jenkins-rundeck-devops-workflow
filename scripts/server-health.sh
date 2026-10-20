#!/usr/bin/env bash
# ==============================================================================
# Server Health Check Script
# Purpose: Comprehensive server inspection for Rundeck Operational Job 1
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}              SERVER HEALTH & INFRASTRUCTURE REPORT                   ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "Report Timestamp : $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo -e "Hostname         : $(hostname)"
echo -e "Kernel Version   : $(uname -r)"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "Operating System : ${PRETTY_NAME}"
fi
echo -e "System Uptime    : $(uptime -p 2>/dev/null || uptime)"
echo ""

# ------------------------------------------------------------------------------
# 1. CPU & System Load
# ------------------------------------------------------------------------------
echo -e "${BOLD}--- [1] CPU & Load Average ---${NC}"
CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
LOAD_AVG=$(uptime | awk -F'load average:' '{ print $2 }' | xargs)
echo -e "CPU Core Count   : ${CPU_CORES}"
echo -e "Load Average     : ${LOAD_AVG}"

# ------------------------------------------------------------------------------
# 2. Memory Utilization
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [2] Memory Utilization ---${NC}"
if command -v free >/dev/null 2>&1; then
    free -m -h
    MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
    MEM_USED=$(free -m | awk '/^Mem:/{print $3}')
    MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    if [ "$MEM_PERCENT" -ge 85 ]; then
        echo -e "Memory Status    : ${RED}WARNING (${MEM_PERCENT}% used)${NC}"
    else
        echo -e "Memory Status    : ${GREEN}OK (${MEM_PERCENT}% used)${NC}"
    fi
else
    echo "Command 'free' not found."
fi

# ------------------------------------------------------------------------------
# 3. Disk Space Utilization
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [3] Disk Space Utilization ---${NC}"
df -h / /var /opt 2>/dev/null || df -h /
ROOT_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$ROOT_USAGE" -ge 85 ]; then
    echo -e "Root Disk Status : ${RED}CRITICAL (${ROOT_USAGE}% full)${NC}"
else
    echo -e "Root Disk Status : ${GREEN}OK (${ROOT_USAGE}% used)${NC}"
fi

# ------------------------------------------------------------------------------
# 4. Critical Services & Process Status
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [4] Critical System Services ---${NC}"
SERVICES=("devops-app" "rundeckd" "jenkins" "ssh" "systemd-journald")

for SVC in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$SVC" 2>/dev/null; then
        echo -e "Service [${SVC}]: ${GREEN}ACTIVE (Running)${NC}"
    elif systemctl is-enabled --quiet "$SVC" 2>/dev/null; then
        echo -e "Service [${SVC}]: ${YELLOW}INACTIVE (Stopped / Enabled)${NC}"
    else
        echo -e "Service [${SVC}]: ${CYAN}NOT INSTALLED or INACTIVE${NC}"
    fi
done

# ------------------------------------------------------------------------------
# 5. Open Listening Ports
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [5] Active Listening Network Ports ---${NC}"
if command -v ss >/dev/null 2>&1; then
    ss -tuln | grep -E 'State|:22|:8080|:4440|:80|:443' || ss -tuln | head -n 10
elif command -v netstat >/dev/null 2>&1; then
    netstat -tuln | head -n 10
else
    echo "Network tools (ss/netstat) not available."
fi

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${GREEN}Server Health Check Completed Successfully.${NC}"
echo -e "${CYAN}======================================================================${NC}"
exit 0
