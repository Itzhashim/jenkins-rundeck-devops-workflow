# Troubleshooting Guide & Operational Diagnostic Playbook

This playbook documents common issues encountered in Jenkins, Rundeck, and Azure Linux environments, with diagnostic steps and verified resolutions.

---

## 1. Jenkins -> Rundeck REST API Connection Issues

### Issue A: HTTP 403 Forbidden or 401 Unauthorized
- **Cause**: The API token passed in `X-Rundeck-Auth-Token` is invalid, expired, or belongs to a user without authorization for the `DevOps-Automation` project.
- **Diagnostics**:
  ```bash
  # Test the token directly using curl
  curl -i -H "X-Rundeck-Auth-Token: <YOUR_TOKEN>" http://<RUNDECK_IP>:4440/api/45/system/info
  ```
- **Resolution**:
  1. In Rundeck, regenerate the API token under **User Profile** -> **User API Tokens** for the `admin` user.
  2. Update the token in Jenkins: **Manage Jenkins** -> **Credentials** -> `RUNDECK_API_TOKEN`.

---

### Issue B: Connection Timed Out / Connection Refused on Port 4440
- **Cause**:
  1. Azure Network Security Group (NSG) is blocking inbound traffic on port 4440.
  2. Rundeck is binding only to localhost (`127.0.0.1`) instead of all network interfaces (`0.0.0.0`).
- **Diagnostics**:
  ```bash
  # Check if rundeckd is listening
  sudo ss -tulnp | grep 4440
  
  # Check Rundeck service status
  sudo systemctl status rundeckd
  ```
- **Resolution**:
  1. In Azure Portal, verify `nsg-rundeck` has an Inbound Security Rule allowing TCP port `4440` from `Any` or your client IP.
  2. Check `/etc/rundeck/rundeck-config.properties`:
     Ensure `grails.serverURL=http://<PUBLIC_IP>:4440` (replace `localhost`).
  3. Restart Rundeck: `sudo systemctl restart rundeckd`.

---

## 2. Application Deployment & Systemd Issues

### Issue A: "Text file busy" or Port 8080 Conflict on Deployment
- **Cause**: An existing Java process is still holding the JAR file or binding to port 8080.
- **Diagnostics**:
  ```bash
  sudo lsof -i :8080
  sudo ss -tulnp | grep :8080
  ```
- **Resolution**:
  1. Ensure the deployment script uses the symlink directory structure (`/opt/devops-app/releases/` and `/opt/devops-app/current/`) rather than overwriting an open file.
  2. Stop the conflicting process:
     ```bash
     sudo systemctl stop devops-app || sudo pkill -f devops-demo-app
     ```

---

### Issue B: "sudo: no tty present and no askpass program specified" in Rundeck
- **Cause**: The `rundeck` user attempted to run a `sudo` command without passwordless sudo privileges configured.
- **Resolution**:
  Verify `/etc/sudoers.d/rundeck-devops` exists with proper permissions (0440):
  ```bash
  sudo cat /etc/sudoers.d/rundeck-devops
  ```
  Ensure it contains:
  ```text
  rundeck ALL=(ALL) NOPASSWD: /bin/systemctl * devops-app, /bin/systemctl status *, /bin/mkdir -p /opt/devops-app*, /bin/chown -R devops\:devops /opt/devops-app*, /bin/cp * /opt/devops-app*, /bin/ln -sf /opt/devops-app*
  ```

---

## 3. Azure Cloud Cost & Dynamic IP Management

### Issue: Public IP Changes After VM Deallocation
- **Cause**: Dynamic public IPs are released when a VM is deallocated in Azure.
- **Resolution**:
  1. The automated deployment script creates **Static Standard Public IPs** (`pip-jenkins`, `pip-rundeck`) to preserve IP assignments across restarts.
  2. If using dynamic IPs, check the new IP after starting VMs:
     ```bash
     az vm list-ip-addresses --resource-group rg-devops-college-project --output table
     ```
  3. Update `RUNDECK_HOST` and `TARGET_SERVER_IP` in Jenkins Credentials accordingly.
