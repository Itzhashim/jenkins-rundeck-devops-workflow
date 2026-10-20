# College Presentation & Demo Walkthrough (8–10 Minutes)

This script provides an exact timed guide and talking points for presenting this project to college professors, evaluators, and viva examiners.

---

## Presentation Breakdown

```
[0:00 - 1:30] Introduction, Architecture & Azure Cloud Design
[1:30 - 3:00] Codebase & Git Workflow
[3:00 - 5:00] Jenkins CI Pipeline (Build, Test, Package, Archive)
[5:00 - 7:30] Rundeck Operations (Jobs, Deployment, Health Checks, Service Management)
[7:30 - 8:45] Failure Scenario & Self-Healing / Rollback Demonstration
[8:45 - 10:00] Azure Cost Governance & Q&A Conclusion
```

---

## Timed Walkthrough & Examiner Talking Points

### 1. Introduction & Architecture (0:00 - 1:30)
- **What to show**: Architecture diagram in [docs/architecture.md](file:///c:/Users/hashi/OneDrive/Documents/Projects/Devops/docs/architecture.md).
- **What to say**:
  > *"Respected evaluators, today I present an enterprise-grade Automated CI/CD and Server Operations Workflow using Jenkins and Rundeck on Microsoft Azure. In standard industry practice, conflating CI and CD inside a build server is an anti-pattern. Build servers should build and test, while dedicated Runbook Automation tools like Rundeck handle operational deployments, server health checks, and service orchestration. Our architecture separates these concerns cleanly across two Azure virtual machines."*

---

### 2. Codebase & Git Walkthrough (1:30 - 3:00)
- **What to show**: GitHub repository structure, Spring Boot application (`AppController.java`, `HealthController.java`), and `pom.xml`.
- **What to say**:
  > *"We built a lightweight Spring Boot 3 microservice that includes REST endpoints, built-in health telemetry with uptime metrics, and automated JUnit 5 tests. The repository includes infrastructure automation scripts, systemd unit configurations, and Rundeck job YAMLs."*

---

### 3. Jenkins CI Pipeline Execution (3:00 - 5:00)
- **What to show**: Jenkins Web UI (`http://<JENKINS_IP>:8080`).
- **What to do**: Click **Build with Parameters** -> **Build**.
- **What to highlight**:
  1. **Stage 1 Checkout**: Pulls Git commit and prints metadata.
  2. **Stage 2 Compile**: Runs Maven compilation.
  3. **Stage 3 Unit Tests**: Executes JUnit tests and publishes the test report.
  4. **Stage 4 Package**: Creates Spring Boot executable JAR.
  5. **Stage 5 Archive**: Preserves artifact with Jenkins fingerprint.
  6. **Stage 7 Trigger Rundeck**: Shows the REST API call passing build number and artifact metadata to Rundeck.
- **What to say**:
  > *"Notice how the Jenkins pipeline is declarative and fully parameterized. Upon successful packaging, Jenkins does not deploy directly; instead, it uses Rundeck's secure REST API with token authentication to trigger the deployment runbook."*

---

### 4. Rundeck Operations Demonstration (5:00 - 7:30)
- **What to show**: Rundeck Web Console (`http://<RUNDECK_IP>:4440`).
- **Jobs to demonstrate**:
  1. **01 - Server Health Check**: Click **Run Job Now**. Point out CPU cores, memory utilization percentage, disk usage, active listening ports, and systemd service states.
  2. **02 - Application Deployment**: Show the execution log triggered by Jenkins. Point out the zero-downtime symlink switch (`/opt/devops-app/current`) and automatic backup creation.
  3. **03 - Application Health Check**: Show the latency metrics and HTTP 200 validation on `/api/health`.
  4. **04 - Service Management**: Show the parameterized dropdowns (`devops-app`, action: `status` or `restart`). Demonstrate the whitelist validation that stops unauthorized commands.
  5. **05 - Scheduled Server Health Check**: Point out the automated cron schedule (`0 0 2 * * ? *`) showing proactive system audits without manual engineer intervention.

---

### 5. Failure Testing & Automated Resilience (7:30 - 8:45)
- **What to do**:
  1. Trigger simulated degradation:
     ```bash
     curl http://<RUNDECK_IP>:8080/api/health/simulate?fail=true
     ```
  2. Run **03 - Application Health Check** in Rundeck.
  3. Show the job failing with **RED status (503 Service Unavailable)**.
  4. Run **04 - Service Management** (`devops-app` -> `restart`).
  5. Re-run **03 - Application Health Check** -> **SUCCESS (GREEN)**.
- **What to say**:
  > *"A key requirement of our project was error handling. Rather than a happy-path-only demo, we implemented simulated runtime failure and demonstrated automated detection and operational recovery via Rundeck runbooks."*

---

### 6. Azure Cost Governance & Conclusion (8:45 - 10:00)
- **What to show**: Azure VM configuration with automated shutdown tags (`19:00 UTC`).
- **What to say**:
  > *"To ensure cost optimization under the Azure Student credit tier, we utilized burstable B-series instances (`Standard_B2s`), static standard IPs, and scheduled automatic resource deallocation. Thank you, I am ready for questions."*

---

## Common Viva / Examiner Questions & Answers

1. **Q: Why use Rundeck instead of writing deployment shell commands directly in Jenkins?**
   - **A**: Conflating CI and CD in Jenkins creates security vulnerabilities (giving Jenkins SSH root access across production fleets) and lacks operational audit trails. Rundeck provides centralized role-based access control (RBAC), self-service operational runbooks for sysadmins, and separation of duties.

2. **Q: How does Jenkins authenticate with Rundeck?**
   - **A**: Jenkins uses a dedicated user API token stored encrypted in Jenkins Credentials (`RUNDECK_API_TOKEN`). It transmits this via the standard HTTP header `X-Rundeck-Auth-Token` to Rundeck's REST API (`POST /api/45/job/<UUID>/run`).

3. **Q: What happens if a deployment introduces a crashing bug?**
   - **A**: Our deployment script implements the atomic symlink pattern with post-deployment health polling. If `/api/health` does not return HTTP 200 within 45 seconds, the script automatically reverts the symlink to the previous backup JAR and restarts the service, preventing downtime.
