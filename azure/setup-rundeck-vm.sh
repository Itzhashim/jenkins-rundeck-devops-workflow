#!/usr/bin/env bash
# ==============================================================================
# Rundeck VM Automated Bootstrap & Setup Script (Ubuntu 22.04 LTS)
# Installs: OpenJDK 17, Rundeck Community, systemd service, devops user & paths
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}              BOOTSTRAPPING RUNDECK OPERATIONS SERVER                 ${NC}"
echo -e "${CYAN}======================================================================${NC}"

PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "localhost")

# 1. Update system package index
echo -e "\n${BOLD}[1/7] Updating APT package repositories...${NC}"
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. Install prerequisites and OpenJDK 17
echo -e "\n${BOLD}[2/7] Installing OpenJDK 17, curl, jq, and utilities...${NC}"
sudo apt-get install -y openjdk-17-jre-headless curl wget jq gnupg apt-transport-https

# 3. Add Rundeck official repository
echo -e "\n${BOLD}[3/7] Adding Rundeck Community repository...${NC}"
curl -s https://packagecloud.io/install/repositories/pagerduty/rundeck/script.deb.sh | sudo bash

# 4. Install Rundeck
echo -e "\n${BOLD}[4/7] Installing Rundeck package...${NC}"
sudo apt-get update -y
sudo apt-get install -y rundeck

# 5. Configure Rundeck server URL and hostnames
echo -e "\n${BOLD}[5/7] Configuring Rundeck server properties (Server IP: ${PUBLIC_IP})...${NC}"
sudo sed -i "s|grails.serverURL=http://localhost:4440|grails.serverURL=http://${PUBLIC_IP}:4440|g" /etc/rundeck/rundeck-config.properties
sudo sed -i "s|framework.server.url = http://localhost:4440|framework.server.url = http://${PUBLIC_IP}:4440|g" /etc/rundeck/framework.properties
sudo sed -i "s|framework.server.hostname = localhost|framework.server.hostname = ${PUBLIC_IP}|g" /etc/rundeck/framework.properties

# 6. Setup Application directories, service user, and permissions
echo -e "\n${BOLD}[6/7] Setting up application directories and security permissions...${NC}"
# Create system user 'devops'
sudo id -u devops &>/dev/null || sudo useradd -r -s /bin/false -d /opt/devops-app devops

# Create deployment directory layout
sudo mkdir -p /opt/devops-app/releases
sudo mkdir -p /opt/devops-app/backups
sudo mkdir -p /opt/devops-app/current
sudo mkdir -p /opt/devops-app/scripts
sudo mkdir -p /opt/devops-app/logs
sudo mkdir -p /tmp/devops-artifacts

# Ensure rundeck user can manage devops directories and execute deployment scripts
sudo usermod -aG devops rundeck 2>/dev/null || true
sudo chown -R devops:devops /opt/devops-app
sudo chmod -R 775 /opt/devops-app
sudo chmod 777 /tmp/devops-artifacts

# Allow rundeck user to run systemctl on devops-app without password
echo "rundeck ALL=(ALL) NOPASSWD: /bin/systemctl * devops-app, /bin/systemctl status *, /bin/systemctl is-active *, /bin/mkdir -p /opt/devops-app*, /bin/chown -R devops\:devops /opt/devops-app*, /bin/cp * /opt/devops-app*, /bin/ln -sf /opt/devops-app*" | sudo tee /etc/sudoers.d/rundeck-devops > /dev/null
sudo chmod 0440 /etc/sudoers.d/rundeck-devops

# 7. Enable and start Rundeck systemd service
echo -e "\n${BOLD}[7/7] Starting Rundeck service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable rundeckd
sudo systemctl restart rundeckd

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${GREEN}✓ Rundeck Operations Server Bootstrap Complete!${NC}"
echo -e "Rundeck Web Console       : http://${PUBLIC_IP}:4440"
echo -e "Default Login Credentials : admin / admin"
echo -e "\nNext Steps in Rundeck Web UI:"
echo "1. Log into http://${PUBLIC_IP}:4440"
echo "2. Create Project: 'DevOps-Automation'"
echo "3. Go to User Profile (top right) -> Generate User API Token"
echo "4. Copy Token and configure in Jenkins Credentials"
echo "5. Import jobs from repository /rundeck/jobs/*.yaml"
echo -e "${CYAN}======================================================================${NC}"
