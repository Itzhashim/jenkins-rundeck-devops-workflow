# Jenkins Configuration & Pipeline Management

This document details how to configure Jenkins to automatically build, test, package the application, and trigger Rundeck operations.

---

## 1. Required Jenkins Plugins

Ensure the following standard plugins are installed (**Manage Jenkins** -> **Plugins** -> **Available Plugins**):
- **Pipeline** (`workflow-aggregator`)
- **Git plugin** (`git`)
- **Timestamper** (`timestamper`)
- **JUnit Plugin** (`junit`)
- **Credentials Binding Plugin** (`credentials-binding`)
- **SSH Agent Plugin** (`ssh-agent`)

---

## 2. Configuring Jenkins Credentials

Navigate to: **Manage Jenkins** -> **Credentials** -> **System** -> **Global credentials (unrestricted)** -> **Add Credentials**.

Create the following credentials:

| Kind | ID / Variable Name | Description | Example Value |
| :--- | :--- | :--- | :--- |
| **Secret text** | `RUNDECK_HOST` | Rundeck Server Base URL | `http://20.120.45.11:4440` |
| **Secret text** | `RUNDECK_API_TOKEN` | User API Token generated in Rundeck | `sX9qLm3Op...` |
| **Secret text** | `TARGET_SERVER_IP` | Public or Private IP of Target App Host | `20.120.45.11` |

> [!IMPORTANT]
> Never hardcode IP addresses or API tokens in the `Jenkinsfile`. Storing them in Jenkins Credentials ensures security and compliance with enterprise DevOps standards.

---

## 3. Creating the Pipeline Job

1. From the Jenkins Dashboard, click **New Item**.
2. Enter the item name: `devops-demo-pipeline`.
3. Select **Pipeline** and click **OK**.
4. Configure Pipeline General Settings:
   - Check **This project is parameterized**:
     - *Parameters will automatically populate from the `Jenkinsfile` on the first run.*
   - Discard old builds: Keep maximum 10 builds.
5. In the **Pipeline** configuration section:
   - **Definition**: Select `Pipeline script from SCM`.
   - **SCM**: Select `Git`.
   - **Repository URL**: `https://github.com/Itzhashim/jenkins-rundeck-devops-workflow.git`
   - **Branch Specifier**: `*/main`
   - **Script Path**: `Jenkinsfile`
6. Click **Save**.

---

## 4. Pipeline Execution Stages

The declarative pipeline defined in [Jenkinsfile](file:///c:/Users/hashi/OneDrive/Documents/Projects/Devops/Jenkinsfile) executes these sequential stages:

```
[1. Checkout Source]
       │
       ▼
[2. Compile & Static Checks] ───────► (Fails if compile syntax errors exist)
       │
       ▼
[3. Run Automated Unit Tests] ──────► (Publishes JUnit XML report; Fails on test assertions)
       │
       ▼
[4. Package Application] ──────────► (Generates Spring Boot JAR via Maven)
       │
       ▼
[5. Archive Artifacts] ────────────► (Archives target/*.jar with Jenkins fingerprint)
       │
       ▼
[6. Publish Artifact] ─────────────► (Transfers JAR to target server release directory)
       │
       ▼
[7. Trigger Rundeck Deployment] ───► (Calls Rundeck REST API with build metadata & parameters)
       │
       ▼
[Post-Actions] ────────────────────► (Reports pipeline health & cleans workspace)
```

---

## 5. Security Safeguards

- If **Compile**, **Test**, or **Package** fails at any stage, pipeline execution aborts immediately.
- Rundeck is strictly **NOT** triggered on failed builds.
- All secrets are masked in the console log via the `credentials()` binding wrapper.
