# System Architecture & Technical Design

## 1. Executive Summary

This project implements an enterprise-grade automated CI/CD and IT Operations workflow using **Jenkins** for Continuous Integration and **Rundeck** for Operations Orchestration, hosted on **Microsoft Azure** Linux infrastructure.

The core design principle separates **Build Automation (CI)** from **Operations Automation (Runbook Automation & CD)**:
- **Jenkins** is responsible exclusively for code validation, unit testing, compiling, packaging, and artifact archival.
- **Rundeck** is responsible for operational runbooks: zero-downtime deployment, service management, infrastructure telemetry, and health monitoring.

---

## 2. End-to-End Workflow Diagram

```
+-----------------------------------------------------------------------------------+
|                                 DEVELOPER WORKSPACE                               |
|                                                                                   |
|  git add .  ==>  git commit -m "feat: new release"  ==>  git push origin main      |
+------------------------------------------+----------------------------------------+
                                           |
                                           | GitHub Webhook / Polling
                                           v
+-----------------------------------------------------------------------------------+
|                         JENKINS CI SERVER (Azure VM 1)                            |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  | [Stage 1] Checkout Source (Git commit verification)                         |  |
|  +-----------------------------------------------------------------------------+  |
|  | [Stage 2] Compile & Static Checks (mvn compile)                             |  |
|  +-----------------------------------------------------------------------------+  |
|  | [Stage 3] Automated Unit Testing (JUnit 5 + MockMvc + Surefire Report)      |  |
|  +-----------------------------------------------------------------------------+  |
|  | [Stage 4] Package Application (Spring Boot Executable JAR)                  |  |
|  +-----------------------------------------------------------------------------+  |
|  | [Stage 5] Archive Artifacts (Jenkins Fingerprint)                           |  |
|  +-----------------------------------------------------------------------------+  |
|  | [Stage 6] Publish Artifact to Target Server Staging (/tmp or /opt)          |  |
|  +-----------------------------------------------------------------------------+  |
|  | [Stage 7] Trigger Rundeck Deployment via REST API (Token Auth)              |  |
|  +-----------------------------------------------------------------------------+  |
|  | [Post-Actions] Success/Failure Notification & Workspace Hygiene             |  |
|  +-----------------------------------------------------------------------------+  |
+------------------------------------------+----------------------------------------+
                                           |
                                           | REST API POST /api/45/job/<UUID>/run
                                           | Header: X-Rundeck-Auth-Token
                                           v
+-----------------------------------------------------------------------------------+
|                   RUNDECK OPERATIONS SERVER & APP HOST (Azure VM 2)               |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  | RUNDECK JOB 02: APPLICATION DEPLOYMENT                                      |  |
|  |  1. Verify artifact checksum in releases directory                          |  |
|  |  2. Create timestamped backup of current JAR in /opt/devops-app/backups/   |  |
|  |  3. Atomically switch /opt/devops-app/current symlink                       |  |
|  |  4. Restart systemd unit (systemctl restart devops-app)                     |  |
|  |  5. Poll /api/health endpoint for startup confirmation                     |  |
|  |  6. Automatic rollback on health verification failure                      |  |
|  +-----------------------------------------------------------------------------+  |
|                                          |                                        |
|                     Triggers Post-Deploy |                                        |
|                                          v                                        |
|  +-----------------------------------------------------------------------------+  |
|  | RUNDECK JOB 03: APPLICATION HEALTH CHECK                                    |  |
|  |  - Tests GET / and GET /api/health                                          |  |
|  |  - Validates HTTP 200, latency, and component status: HEALTHY              |  |
|  +-----------------------------------------------------------------------------+  |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  | RUNDECK JOB 01: SERVER HEALTH CHECK                                         |  |
|  |  - CPU, RAM, Load average, Disk space, listening ports, systemd services    |  |
|  +-----------------------------------------------------------------------------+  |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  | RUNDECK JOB 04: SERVICE MANAGEMENT                                          |  |
|  |  - Parameterized control: [service] + [start | stop | restart | status]     |  |
|  |  - Parameter whitelisting for security protection                          |  |
|  +-----------------------------------------------------------------------------+  |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  | RUNDECK JOB 05: SCHEDULED MAINTENANCE CHECK                                 |  |
|  |  - Automated crontab execution for hands-off operational audits            |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## 3. Infrastructure Architecture on Microsoft Azure

To maximize demonstration clarity and adhere to Azure Student subscription credit limits ($100 budget), the architecture uses two burstable B-series virtual machines:

| Component | Virtual Machine | VM Size | OS Image | Purpose | Open Ports |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **CI Server** | `vm-jenkins` | `Standard_B2s` (2 vCPU, 4GB RAM) | Ubuntu 22.04 LTS | Jenkins LTS, Maven, Git, JDK 17 | `22` (SSH), `8080` (Web UI) |
| **Ops Server** | `vm-rundeck` | `Standard_B2s` (2 vCPU, 4GB RAM) | Ubuntu 22.04 LTS | Rundeck Community, Java app runtime, systemd | `22` (SSH), `4440` (Rundeck), `8080` (App) |

### Cloud Security Architecture
1. **Network Security Groups (NSGs)**:
   - `nsg-jenkins`: Restricted ingress to port 22 and 8080.
   - `nsg-rundeck`: Restricted ingress to port 22, 4440, and 8080.
2. **Cost Governance & Auto-Shutdown**:
   - Both VMs are tagged with automated daily shutdown (`19:00 UTC`) via Azure Resource Manager (`az vm auto-shutdown`). This prevents inadvertent credit consumption when not presenting.

---

## 4. Key Architectural Improvements & DevOps Decisions

### 1. Spring Boot 3 with Embedded Actuator vs. Raw Java Sockets
- **Why**: Evaluators immediately recognize Spring Boot as an industry-standard framework. Built-in actuator endpoints (`/api/health`, `/actuator/info`) provide realistic production-style health signals without unnecessary boilerplate.

### 2. Native REST API Integration vs. Third-Party Jenkins Plugins
- **Why**: Rundeck Jenkins plugins often encounter version incompatibilities or require complex Jenkins plugin administration. Using Rundeck's native REST API (`POST /api/45/job/<UUID>/run`) with token-based authentication (`X-Rundeck-Auth-Token`) is completely portable, reliable across Jenkins versions, and allows clean error inspection directly in Jenkins logs.

### 3. Atomic Symlink Deployment & Auto-Rollback Pattern
- **Why**: Rather than copying files directly over a running JAR (which causes `Text file busy` Linux errors), the deployment script:
  1. Stores build-specific jars in `/opt/devops-app/releases/devops-demo-app-build-${BUILD_NUMBER}.jar`.
  2. Creates a timestamped backup in `/opt/devops-app/backups/`.
  3. Atomically swaps the symlink `/opt/devops-app/current/devops-demo-app.jar`.
  4. If post-deploy health polling fails, the symlink is immediately rolled back to the previous release and restarted.

### 4. Parameterized Operations with Input Whitelisting
- **Why**: Rundeck operations jobs should empower operators while preventing security risks. The Service Management job strictly validates input parameters against an allowed whitelist (`devops-app`, `rundeckd`, `jenkins`, `ssh`, `nginx`) and approved actions (`status`, `restart`, `start`, `stop`), preventing shell injection.
