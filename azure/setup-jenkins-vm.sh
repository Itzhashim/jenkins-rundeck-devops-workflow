#!/usr/bin/env bash
# ==============================================================================
# Jenkins VM Automated Bootstrap & Setup Script (Ubuntu 22.04 LTS)
# Installs: OpenJDK 17, Apache Maven, Git, Jenkins LTS, and build dependencies
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}              BOOTSTRAPPING JENKINS CI SERVER                         ${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Update system package index
echo -e "\n${BOLD}[1/6] Updating APT package repositories...${NC}"
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. Install prerequisites and OpenJDK 17
echo -e "\n${BOLD}[2/6] Installing OpenJDK 17, Git, Maven, and utilities...${NC}"
sudo apt-get install -y openjdk-17-jdk maven git curl wget jq unzip ufw apt-transport-https

# Verify Java and Maven
java -version
mvn -version

# 3. Add Jenkins LTS official repository and key
echo -e "\n${BOLD}[3/6] Adding official Jenkins LTS repository...${NC}"
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# 4. Install Jenkins
echo -e "\n${BOLD}[4/6] Installing Jenkins package...${NC}"
sudo apt-get update -y
sudo apt-get install -y jenkins

# 5. Enable and start Jenkins service
echo -e "\n${BOLD}[5/6] Enabling and starting Jenkins systemd service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl restart jenkins

# Wait for Jenkins to initialize and generate initialAdminPassword
echo "Waiting for Jenkins initialization (approx. 20 seconds)..."
sleep 20

# 6. Output status and initial credentials
echo -e "\n${BOLD}[6/6] Configuration Summary:${NC}"
PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "localhost")
echo -e "${GREEN}✓ Jenkins service is ACTIVE and running!${NC}"
echo -e "Jenkins URL               : http://${PUBLIC_IP}:8080"
echo -e "Initial Admin Password    :"
echo -e "${CYAN}----------------------------------------------------------------------${NC}"
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Password file still generating. Check: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi
echo -e "${CYAN}----------------------------------------------------------------------${NC}"
echo -e "\nRecommended Jenkins Plugins to install during initial setup:"
echo " - Git plugin"
echo " - Pipeline"
echo " - Timestamper"
echo " - JUnit Plugin"
echo " - SSH Agent Plugin"
echo "======================================================================"
