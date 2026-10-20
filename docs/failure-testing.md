# Failure Testing & Resilience Demonstration Matrix

Enterprise DevOps systems must fail safely and recover gracefully. This document details the exact reproduction steps for 6 resilience scenarios to demonstrate during college examinations.

---

## Resilience Scenarios Overview

| Scenario | Simulated Defect | Trigger Point | Expected Behavior | Recovery Action |
| :--- | :--- | :--- | :--- | :--- |
| **1. Happy Path** | Valid code & passing tests | Normal commit | Jenkins GREEN ➔ Rundeck triggers ➔ App healthy | None needed |
| **2. Compilation Failure** | Java syntax error | Jenkins Stage 2 | Jenkins FAILS immediately. Rundeck is NOT triggered | Fix syntax error & commit |
| **3. Unit Test Failure** | Asserting wrong expected value | Jenkins Stage 3 | JUnit reports test failure. Build fails. Rundeck NOT triggered | Fix unit test logic & commit |
| **4. Deployment Failure** | Missing artifact file or bad config | Rundeck Job 2 | Deployment job fails. Health check aborts | Re-run with valid artifact |
| **5. Health Check Failure** | Runtime degradation toggle | App `/api/health` | Rundeck Job 3 reports RED/503. Job 2 triggers automated rollback | Reset toggle or trigger Job 4 restart |
| **6. Automated Rollback** | Bad version deployed | Rundeck Job 2 | Deploy script rolls back symlink to previous working JAR | Restores stable version automatically |

---

## Detailed Step-by-Step Reproduction Instructions

### Scenario 1: Successful Happy Path Execution
1. Push any normal commit to `main`.
2. In Jenkins: Build triggers, passes Compile, Unit Tests, Package, Archive.
3. Jenkins invokes Rundeck REST API.
4. In Rundeck: Job `02 - Application Deployment` executes:
   - Symlink updated
   - Service restarted
   - Health check verified
5. Result: **100% Green across Jenkins and Rundeck.**

---

### Scenario 2: Compilation Failure
1. Edit `src/main/java/com/devops/demo/DevopsDemoApplication.java` and introduce a syntax error (e.g. remove a semicolon or add random text).
2. Commit and push:
   ```bash
   git commit -am "test: introduce syntax error"
   git push origin main
   ```
3. Observe Jenkins:
   - Fails at **Stage 2: Compile & Static Checks**.
   - Red pipeline status.
   - **Crucial Observation**: Rundeck deployment job is **NEVER** triggered. Production remains safe and untouched.

---

### Scenario 3: Unit Test Failure
1. Edit `src/test/java/com/devops/demo/controller/AppControllerTest.java`.
2. Change the expected version from `"1.0.0"` to `"9.9.9"`:
   ```java
   .andExpect(jsonPath("$.version").value("9.9.9"));
   ```
3. Commit and push:
   ```bash
   git commit -am "test: introduce failing unit test"
   git push origin main
   ```
4. Observe Jenkins:
   - Stage 2 (Compile) passes.
   - Stage 3 (Run Automated Unit Tests) fails with `AssertionError`.
   - Jenkins records test result in the **Test Result Trend** graph.
   - Pipeline marks build as **FAILURE**.
   - Rundeck is **NOT** triggered.

---

### Scenario 4 & 5: Health Check Failure & Simulated Runtime Degradation
Our application includes a live simulation endpoint built for college demonstrations:
- Endpoint: `GET /api/health/simulate?fail=true`

1. Open a browser or terminal and call:
   ```bash
   curl http://<RUNDECK_IP>:8080/api/health/simulate?fail=true
   ```
2. Now run **Job 03 - Application Health Check** in Rundeck.
3. Observe Rundeck:
   - Output turns **RED**.
   - HTTP response code: `503 Service Unavailable`.
   - Status payload: `"status": "UNHEALTHY"`.
   - Rundeck job marks execution as **FAILED**.

---

### Scenario 6: Service Recovery & Restoration
You can demonstrate two recovery methods to evaluators:

#### Method A: Using Rundeck Job 04 (Service Management)
1. Go to Rundeck -> **Jobs** -> **04 - Service Management**.
2. Select:
   - `SERVICE_NAME`: `devops-app`
   - `ACTION`: `restart`
3. Click **Run Job Now**.
4. The service restarts with fresh runtime memory (clearing the simulated flag).
5. Re-run **03 - Application Health Check** -> **SUCCESS (GREEN)**.

#### Method B: Automated Rollback in Job 02 (Deployment Script)
- The deployment script in [scripts/deploy.sh](file:///c:/Users/hashi/OneDrive/Documents/Projects/Devops/scripts/deploy.sh) automatically preserves the previous release JAR in `/opt/devops-app/backups/`.
- If an updated JAR fails the post-deployment health check polling within 45 seconds, the script automatically reverts the symlink `/opt/devops-app/current/devops-demo-app.jar` back to the backup and restarts the service!
