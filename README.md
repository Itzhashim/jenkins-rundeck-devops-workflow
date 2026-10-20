# Automated CI/CD and Server Operations using Jenkins and Rundeck

[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)]()
[![Framework](https://img.shields.io/badge/Spring%20Boot-3.3.4-blue.svg)]()
[![CI](https://img.shields.io/badge/CI-Jenkins%20LTS-orange.svg)]()
[![Operations](https://img.shields.io/badge/Operations-Rundeck%20Community-red.svg)]()
[![Cloud](https://img.shields.io/badge/Cloud-Microsoft%20Azure-0078D4.svg)]()

> A production-grade DevOps engineering system demonstrating automated continuous integration with Jenkins and runbook operations automation with Rundeck on Microsoft Azure Linux virtual machines.

---

## 1. Project Title
**Automated CI/CD and Server Operations using Jenkins and Rundeck**  
*(Alternative Title: Jenkins + Rundeck Automated Build and Operations Workflow)*

---

## 2. Problem Statement
In modern software engineering, conflating Continuous Integration (CI) and Continuous Deployment/Operations (CD/Ops) inside a single build server introduces critical reliability and security challenges:
- Giving CI servers unrestricted root SSH access to production fleets expands the blast radius during security breaches.
- Build logs become cluttered with operational maintenance tasks, making troubleshooting difficult.
- Sysadmins and operations teams lack self-service, audited runbooks to manage services, inspect system health, and trigger rollbacks without developers.

This project solves this by separating **CI (Build & Validation Automation)** handled by **Jenkins** from **CD & Operational Automation** managed by **Rundeck**.

---

## 3. Objectives
1. **Automated CI Pipeline**: Build, compile, test, and package a Java Spring Boot application automatically upon code commit.
2. **Quality Gateways**: Ensure builds fail properly if unit tests fail or code cannot compile, blocking any downstream deployment.
3. **Decoupled Operations**: Trigger Rundeck operational runbooks exclusively via secure REST APIs upon successful builds.
4. **Zero-Downtime Deployment**: Implement an atomic symlink deployment pattern with automated backup and rollback.
5. **Infrastructure & Application Telemetry**: Provide one-click and scheduled health checks for CPU, RAM, disk, listening ports, and HTTP latency.
6. **Cost Governance**: Design an Azure Student-friendly architecture with automated shutdown schedules to prevent budget exhaustion.

---

## 4. Architecture Overview

```
                      +-----------------------------+
                      |     DEVELOPER WORKSPACE     |
                      |   Git Commit / Push to main |
                      +--------------+--------------+
                                     |
                                     v
                      +-----------------------------+
                      |      GITHUB REPOSITORY      |
                      +--------------+--------------+
                                     |
                                     v
  +--------------------------------------------------------------------+
  |                   JENKINS CI SERVER (Azure VM 1)                   |
  |                                                                    |
  |  [Checkout] ➔ [Compile] ➔ [JUnit Tests] ➔ [Package] ➔ [Archive]    |
  |                                                                    |
  |         Triggers Rundeck REST API (POST /api/45/job/run)           |
  +----------------------------------+---------------------------------+
                                     |
                                     v
  +--------------------------------------------------------------------+
  |            RUNDECK OPERATIONS & APP SERVER (Azure VM 2)            |
  |                                                                    |
  |  +--------------------------------------------------------------+  |
  |  | Job 02: Application Deployment                               |  |
  |  |  - Preserves backup in /opt/devops-app/backups/              |  |
  |  |  - Updates /opt/devops-app/current symlink                   |  |
  |  |  - Restarts devops-app.service via systemd                   |  |
  |  |  - Polls /api/health with automated rollback on failure      |  |
  |  +--------------------------------------------------------------+  |
  |                                                                    |
  |  +--------------------------------------------------------------+  |
  |  | Job 01: Server Health Check (CPU, RAM, Disk, Services)       |  |
  |  +--------------------------------------------------------------+  |
  |  | Job 03: Application Health Check (HTTP 200 & Latency)        |  |
  |  +--------------------------------------------------------------+  |
  |  | Job 04: Parameterized Service Management (start/stop/restart)|  |
  |  +--------------------------------------------------------------+  |
  |  | Job 05: Scheduled Maintenance Health Check (Crontab)         |  |
  |  +--------------------------------------------------------------+  |
  +--------------------------------------------------------------------+
```

Detailed architectural diagrams and decisions are documented in [docs/architecture.md](docs/architecture.md).

---

## 5. Technology Stack

| Category | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Version Control** | Git & GitHub | Latest | Source code management and CI webhook triggers |
| **Application** | Java / Spring Boot | JDK 17+ / Spring Boot 3.3.4 | Lightweight REST service with `/api/health` telemetry |
| **Build Tool** | Apache Maven | 3.8+ / 3.9+ | Dependency management, compilation, and packaging |
| **CI Server** | Jenkins LTS | 2.452+ | Continuous Integration pipeline and automated testing |
| **Operations** | Rundeck Community | 5.x (API v45) | Runbook automation, deployment, and service operations |
| **Operating System** | Ubuntu Linux | 22.04 LTS | Standard server platform for enterprise workloads |
| **Cloud Hosting** | Microsoft Azure | Azure Student Tier | Virtual machines, VNets, and Network Security Groups |
| **Process Manager** | Linux `systemd` | systemd 249 | Reliable service lifecycle management and journal logging |

---

## 6. Project Structure

```
devops-rundeck-project/
├── pom.xml                               # Maven project configuration and dependencies
├── Jenkinsfile                           # Declarative Jenkins CI pipeline definition
├── .gitignore                            # Git exclusion rules (build artifacts, keys, logs)
├── .env.example                          # Environment variable configuration template
├── README.md                             # Comprehensive project documentation
│
├── src/                                  # Spring Boot Application Source Code
│   ├── main/
│   │   ├── java/com/devops/demo/
│   │   │   ├── DevopsDemoApplication.java # Spring Boot entry point
│   │   │   ├── model/AppStatus.java       # JSON status model
│   │   │   └── controller/
│   │   │       ├── AppController.java     # Root (/) and /api/info endpoints
│   │   │       └── HealthController.java  # /api/health and /api/health/simulate endpoints
│   │   └── resources/
│   │       └── application.properties    # Server port and actuator config
│   └── test/
│       └── java/com/devops/demo/         # Automated JUnit 5 Unit Tests
│           ├── DevopsDemoApplicationTests.java
│           └── controller/
│               ├── AppControllerTest.java
│               └── HealthControllerTest.java
│
├── scripts/                              # Operational Shell Scripts executed by Rundeck
│   ├── deploy.sh                         # Zero-downtime deployment and auto-rollback
│   ├── health-check.sh                   # Application HTTP endpoint validator
│   ├── server-health.sh                  # Comprehensive server metrics and load inspector
│   ├── service-management.sh             # Parameterized service controller with whitelisting
│   └── trigger-rundeck.sh                # Helper script for testing Rundeck REST API
│
├── rundeck/
│   └── jobs/                             # Exportable / Importable Rundeck Job YAMLs
│       ├── 01-server-health-check.yaml
│       ├── 02-application-deployment.yaml
│       ├── 03-application-health-check.yaml
│       ├── 04-service-management.yaml
│       └── 05-scheduled-maintenance-check.yaml
│
├── systemd/
│   └── devops-app.service                # Production systemd unit configuration
│
├── azure/                                # Cloud Infrastructure Automation
│   ├── deploy-azure-resources.sh         # Azure CLI automated provisioning script
│   ├── deploy-azure-resources.ps1        # PowerShell automated provisioning script
│   ├── setup-jenkins-vm.sh               # Jenkins VM bootstrap script
│   └── setup-rundeck-vm.sh               # Rundeck VM bootstrap script
│
└── docs/                                 # Documentation & College Presentation Artifacts
    ├── architecture.md                   # System architecture and design decisions
    ├── setup.md                          # Step-by-step installation and provisioning guide
    ├── jenkins.md                        # Jenkins configuration and credentials setup
    ├── rundeck.md                        # Rundeck project, tokens, and jobs walkthrough
    ├── failure-testing.md                # 6 Resilience and error handling scenarios
    ├── troubleshooting.md                # Diagnostic and resolution playbook
    ├── demo-guide.md                     # 8-10 Minute presentation script and viva Q&A
    └── screenshots-checklist.md          # Visual documentation checklist for report
```

---

## 7. Setup Requirements

1. **Local Environment**:
   - Java Development Kit (JDK 17 or higher)
   - Apache Maven 3.8+
   - Git and OpenSSH client
2. **Azure Account**:
   - Azure for Students subscription ($100 credit) or standard subscription.
3. **GitHub**:
   - A GitHub repository containing this codebase.

---

## 8. Azure Infrastructure Provisioning

Run the automated provisioning script directly inside Azure Cloud Shell:
```bash
chmod +x azure/deploy-azure-resources.sh
./azure/deploy-azure-resources.sh
```

This provisions:
- Resource Group: `rg-devops-college-project` in `eastus`
- `vm-jenkins` (`Standard_B2s`, Ubuntu 22.04 LTS) for CI
- `vm-rundeck` (`Standard_B2s`, Ubuntu 22.04 LTS) for CD & Application
- Static Standard Public IPs
- Network Security Groups with strictly required ports (22, 8080, 4440)
- **Auto-Shutdown at 19:00 UTC** to protect student credits.

---

## 9. Jenkins Configuration

Detailed instructions are available in [docs/jenkins.md](docs/jenkins.md).

1. Log into Jenkins (`http://<JENKINS_IP>:8080`).
2. Install recommended plugins (`git`, `pipeline`, `junit`, `credentials-binding`, `ssh-agent`).
3. Add Global Credentials:
   - `RUNDECK_HOST`: `http://<RUNDECK_IP>:4440`
   - `RUNDECK_API_TOKEN`: User API Token generated in Rundeck
   - `TARGET_SERVER_IP`: Public IP of `vm-rundeck`
4. Create a Pipeline Job:
   - SCM: `Git` pointing to your GitHub repo.
   - Script Path: `Jenkinsfile`.

---

## 10. Rundeck Configuration

Detailed instructions are available in [docs/rundeck.md](docs/rundeck.md).

1. Log into Rundeck (`http://<RUNDECK_IP>:4440`) with credentials `admin` / `admin`.
2. Create Project: `DevOps-Automation`.
3. Generate User API Token: Under **Profile** -> **User API Tokens**.
4. Import Jobs: Under **Jobs** -> **Job Actions** -> **Upload Definition**, upload all YAML files from `rundeck/jobs/`.

---

## 11. Jenkins-to-Rundeck Integration

Jenkins triggers Rundeck via Rundeck's native REST API v45:
```http
POST /api/45/job/7b8e5c12-3456-4789-a1b2-c3d4e5f60002/run
Host: <RUNDECK_IP>:4440
X-Rundeck-Auth-Token: <SECRET_TOKEN>
Content-Type: application/json

{
  "options": {
    "BUILD_NUMBER": "14",
    "ARTIFACT_NAME": "devops-demo-app-1.0.0.jar",
    "ENVIRONMENT": "production"
  }
}
```
**Why REST API?**
- Eliminates brittle third-party plugin version incompatibilities.
- Completely portable across cloud environments.
- Directly captures execution IDs and URLs in Jenkins logs.

---

## 12. Deployment Workflow

1. Artifact is transferred to `/opt/devops-app/releases/devops-demo-app-build-${BUILD_NUMBER}.jar`.
2. Previous active JAR is backed up to `/opt/devops-app/backups/`.
3. Atomic symlink `/opt/devops-app/current` is switched to the new release.
4. `systemctl restart devops-app` is executed.
5. The script polls `http://localhost:8080/api/health` for startup confirmation.
6. **Automatic Rollback**: If the application fails to become healthy within 45 seconds, the symlink is immediately rolled back to the backup and the service is restored.

---

## 13. Health Check Workflow

- **Server Health Check (Job 01)**: Gathers CPU core count, load average (1m, 5m, 15m), memory utilization %, disk usage %, listening ports, and status of `devops-app`, `rundeckd`, and `ssh`.
- **Application Health Check (Job 03)**:
  - Validates `GET /` -> HTTP 200, checks version and application name.
  - Validates `GET /api/health` -> HTTP 200, latency measurement (< 50ms), and checks component health (`webServer`, `memory`, `disk`).

---

## 14. Security Considerations

1. **No Hardcoded Secrets**: All passwords, API tokens, and SSH keys are managed via Jenkins Credentials and environment parameters.
2. **Least Privilege System User**: The application runs under an unprivileged system user `devops` with systemd sandboxing (`ProtectSystem=full`, `PrivateTmp=true`, `NoNewPrivileges=true`).
3. **Command Injection Prevention**: Parameterized Rundeck jobs use strict bash array whitelisting (`ALLOWED_SERVICES` and `ALLOWED_ACTIONS`).
4. **Network Security Groups**: External access is restricted strictly to required administration ports.

---

## 15. Testing & Failure Handling

We tested and verified 6 distinct operational resilience scenarios:
1. **Successful Pipeline Run**: Code passes tests, packages, triggers Rundeck, deploys, and passes health check.
2. **Compilation Failure**: Syntax errors stop Jenkins at Stage 2; Rundeck is never called.
3. **Unit Test Failure**: Assertion failures fail the build in Jenkins; JUnit reports recorded; Rundeck blocked.
4. **Deployment Failure**: Missing artifact triggers immediate error log and stops execution.
5. **Runtime Health Failure**: Calling `/api/health/simulate?fail=true` causes Rundeck Job 03 to fail with HTTP 503.
6. **Self-Healing Recovery**: Using Rundeck Job 04 (Service Management) to restart the service automatically restores health.

Full reproduction steps are documented in [docs/failure-testing.md](docs/failure-testing.md).

---

## 16. Troubleshooting
Common issues such as HTTP 403 API token errors, port 4440 NSG rules, sudo permissions, and dynamic Azure IPs are addressed with exact diagnostic commands in [docs/troubleshooting.md](docs/troubleshooting.md).

---

## 17. Screenshots to Capture
A comprehensive 18-point screenshot checklist for your college report is detailed in [docs/screenshots-checklist.md](docs/screenshots-checklist.md).

---

## 18. Future Improvements
1. **Containerization (Optional)**: Transition deployment to container orchestration if microservices scale.
2. **Infrastructure as Code (IaC)**: Migrate Azure VM provisioning to Terraform or Bicep for GitOps infrastructure management.
3. **Monitoring & Alerting**: Integrate Prometheus and Grafana dashboards with Slack / Microsoft Teams webhook notifications on Rundeck job failures.
4. **Canary Deployments**: Leverage Nginx upstream switching to support blue/green or canary traffic routing during new version rollouts.
