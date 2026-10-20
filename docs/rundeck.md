# Rundeck Configuration & Operations Guide

Rundeck acts as the centralized Operations Management and Runbook Automation platform in this architecture.

---

## 1. Initial Project Setup

1. Open your browser and navigate to `http://<RUNDECK_PUBLIC_IP>:4440`.
2. Log in with credentials (`admin` / `admin`).
3. Click **New Project**:
   - **Project Name**: `DevOps-Automation`
   - **Label**: `DevOps Automation & Operations`
   - **Description**: `Operational runbooks for CI/CD deployment, server health checks, and service management.`
   - Leave default node execution settings and click **Create**.

---

## 2. Generating the User API Token (For Jenkins Integration)

1. Click on the **User Profile** icon in the top-right corner (marked as `admin`).
2. Navigate to **User Profile** -> **User API Tokens**.
3. Click **Generate New Token**:
   - **Name**: `jenkins-ci-token`
   - **Roles**: `admin`
   - **Expiration**: Set appropriate duration or leave blank for demo.
4. Click **Generate Token**.
5. Copy the generated token string immediately and configure it in Jenkins Credentials as `RUNDECK_API_TOKEN`.

---

## 3. Importing Operational Jobs

The repository provides ready-to-import YAML definitions in `rundeck/jobs/`.

You can import them in seconds:

1. Inside your Rundeck project (`DevOps-Automation`), click **Jobs** in the left sidebar.
2. In the top-right **Job Actions** dropdown menu, select **Upload Definition**.
3. Upload each YAML file from `rundeck/jobs/`:
   - `01-server-health-check.yaml`
   - `02-application-deployment.yaml`
   - `03-application-health-check.yaml`
   - `04-service-management.yaml`
   - `05-scheduled-maintenance-check.yaml`
4. Set format to **YAML** and click **Upload**.

---

## 4. Operational Job Details

### Job 1: 01 - Server Health Check
- **UUID**: `7b8e5c12-3456-4789-a1b2-c3d4e5f60001`
- **Group**: `Operations/Infrastructure`
- **Purpose**: Gathers system metrics including load averages, CPU cores, memory utilization percentage, root filesystem disk consumption, active listening ports, and critical systemd service statuses.
- **How to Run**: Click **Run Job Now**. Output is formatted with clean status indicators.

---

### Job 2: 02 - Application Deployment
- **UUID**: `7b8e5c12-3456-4789-a1b2-c3d4e5f60002`
- **Group**: `Deployment`
- **Purpose**: Deploys a new Spring Boot artifact without disrupting previous releases.
- **Parameters / Options**:
  - `BUILD_NUMBER`: (e.g. `14` or `latest`)
  - `ARTIFACT_NAME`: (default: `devops-demo-app-1.0.0.jar`)
  - `ENVIRONMENT`: (`production` or `staging`)
- **Key Features**:
  - Creates backup in `/opt/devops-app/backups/`.
  - Performs atomic symlink swap `/opt/devops-app/current`.
  - Reloads and restarts `devops-app.service`.
  - Automatically polls `/api/health` for startup confirmation.
  - Automatically rolls back to the previous backup if startup or health verification fails!

---

### Job 3: 03 - Application Health Check
- **UUID**: `7b8e5c12-3456-4789-a1b2-c3d4e5f60003`
- **Group**: `Operations/Application`
- **Purpose**: Verifies that the deployed application is running properly and responsive.
- **Parameters / Options**:
  - `TARGET_HOST`: default `localhost`
  - `TARGET_PORT`: default `8080`
- **Validation**:
  - Checks HTTP 200 on `/` and `/api/health`.
  - Validates latency in milliseconds.
  - Asserts that JSON payload contains `"status": "HEALTHY"`.

---

### Job 4: 04 - Service Management
- **UUID**: `7b8e5c12-3456-4789-a1b2-c3d4e5f60004`
- **Group**: `Operations/System`
- **Purpose**: Parameterized service management runbook with input sanitization.
- **Parameters / Options**:
  - `SERVICE_NAME`: Dropdown choice [`devops-app`, `rundeckd`, `jenkins`, `ssh`, `nginx`]
  - `ACTION`: Dropdown choice [`status`, `restart`, `start`, `stop`, `reload`]
- **Security Whitelisting**:
  - The script checks the parameters against an approved whitelist to prevent arbitrary command injection.

---

### Job 5: 05 - Scheduled Server Health Check
- **UUID**: `7b8e5c12-3456-4789-a1b2-c3d4e5f60005`
- **Group**: `Scheduled Operations`
- **Schedule**: Crontab `0 0 2 * * ? *` (Daily at 02:00 AM UTC)
- **Demonstration Value**: Proves that routine operational audits occur automatically without a human engineer needing to log into the production server.
