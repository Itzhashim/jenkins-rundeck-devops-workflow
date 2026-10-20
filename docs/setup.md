# Setup and Installation Guide

This guide walks you through provisioning the cloud infrastructure and configuring the Jenkins and Rundeck environments.

---

## 1. Prerequisites

1. **Azure Account** (e.g., Azure for Students subscription with active credits).
2. **Local Workstation**:
   - Git installed (`git --version`)
   - Java 17+ and Maven 3.8+ (for local builds and tests)
   - OpenSSH client (`ssh -V`)
3. **GitHub Account**:
   - Fork or clone this repository to your personal GitHub account.

---

## 2. Azure Infrastructure Setup

You can provision the required resources either automatically using the provided scripts or manually via Azure Portal.

### Method A: Automated Deployment via Azure CLI / Cloud Shell (Recommended)

1. Open [Azure Portal](https://portal.azure.com) and click the **Cloud Shell** icon (`>_`) in the top navigation bar (select Bash).
2. Clone your repository in Cloud Shell:
   ```bash
   git clone https://github.com/Itzhashim/jenkins-rundeck-devops-workflow.git
   cd jenkins-rundeck-devops-workflow
   ```
3. Run the provisioning script:
   ```bash
   chmod +x azure/deploy-azure-resources.sh
   ./azure/deploy-azure-resources.sh
   ```
   *(On a local Windows machine with Azure CLI installed, you can alternatively run `powershell ./azure/deploy-azure-resources.ps1`).*

4. Note down the public IP addresses printed at the conclusion of the script:
   - `Jenkins Server Public IP`: e.g. `20.120.45.10`
   - `Rundeck Server Public IP`: e.g. `20.120.45.11`

---

## 3. Jenkins CI Server Setup (VM 1)

1. SSH into the Jenkins VM:
   ```bash
   ssh azureuser@<JENKINS_PUBLIC_IP>
   ```

2. Download and run the automated Jenkins bootstrap script:
   ```bash
   # Clone the repo or copy the bootstrap script
   git clone https://github.com/Itzhashim/jenkins-rundeck-devops-workflow.git
   cd jenkins-rundeck-devops-workflow
   chmod +x azure/setup-jenkins-vm.sh
   ./azure/setup-jenkins-vm.sh
   ```

3. Copy the **initial admin password** printed at the end of the script:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

4. Complete Web UI Setup:
   - Navigate to `http://<JENKINS_PUBLIC_IP>:8080` in your browser.
   - Enter the Administrator password.
   - Choose **Install suggested plugins**.
   - Create your Admin User account (e.g., `admin` / `YourSecurePassword123!`).

---

## 4. Rundeck Operations Server Setup (VM 2)

1. SSH into the Rundeck VM:
   ```bash
   ssh azureuser@<RUNDECK_PUBLIC_IP>
   ```

2. Run the automated Rundeck bootstrap script:
   ```bash
   git clone https://github.com/Itzhashim/jenkins-rundeck-devops-workflow.git
   cd jenkins-rundeck-devops-workflow
   chmod +x azure/setup-rundeck-vm.sh
   ./azure/setup-rundeck-vm.sh
   ```

3. Copy the system scripts and systemd unit into place:
   ```bash
   sudo cp -r scripts/* /opt/devops-app/scripts/
   sudo chmod +x /opt/devops-app/scripts/*.sh
   sudo cp systemd/devops-app.service /etc/systemd/system/
   sudo systemctl daemon-reload
   ```

4. Access Rundeck Web UI:
   - Open `http://<RUNDECK_PUBLIC_IP>:4440` in your browser.
   - Log in with default credentials:
     - **Username**: `admin`
     - **Password**: `admin`
     *(Change the password in production under `/etc/rundeck/realm.properties`).*

---

## 5. Cost Control & Student Credit Management

To avoid wasting Azure Student credit when not actively working:

```bash
# Deallocate VMs (stops billing for compute hours)
az vm deallocate --resource-group rg-devops-college-project --name vm-jenkins
az vm deallocate --resource-group rg-devops-college-project --name vm-rundeck

# Start VMs when preparing for a presentation or demo
az vm start --resource-group rg-devops-college-project --name vm-jenkins
az vm start --resource-group rg-devops-college-project --name vm-rundeck
```
*(Both VMs also have auto-shutdown configured for 19:00 UTC daily as a safety mechanism).*
