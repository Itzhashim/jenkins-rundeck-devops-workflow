# College Documentation Screenshot Checklist

Capture these screenshots during deployment and testing to include in your project report, presentation slides, and viva documentation.

| Screenshot # | Title / View | Where to Capture | What to Highlight |
| :---: | :--- | :--- | :--- |
| **01** | **GitHub Repository Overview** | GitHub Browser Tab | Project structure (`src/`, `scripts/`, `rundeck/`, `Jenkinsfile`, `pom.xml`, `README.md`) |
| **02** | **Azure Resource Group & VMs** | Azure Portal (`rg-devops-college-project`) | Both VMs (`vm-jenkins` & `vm-rundeck`), IP addresses, and Auto-Shutdown schedule tag |
| **03** | **Network Security Groups (NSGs)** | Azure Portal (`nsg-jenkins`, `nsg-rundeck`) | Inbound security rules for ports 22, 8080, and 4440 |
| **04** | **Jenkins Dashboard** | Jenkins Web UI (`http://<JENKINS_IP>:8080`) | Job `devops-demo-pipeline`, build history, weather report icon |
| **05** | **Jenkins Credentials Store** | Jenkins -> Manage Jenkins -> Credentials | Configured `RUNDECK_HOST`, `RUNDECK_API_TOKEN`, and `TARGET_SERVER_IP` secrets |
| **06** | **Successful Jenkins Pipeline Stages** | Jenkins Pipeline Stage View | All green stages: Checkout ➔ Compile ➔ Test ➔ Package ➔ Archive ➔ Trigger Rundeck |
| **07** | **JUnit Test Results in Jenkins** | Jenkins -> Build -> Test Result | 3 Passing tests (`AppControllerTest`, `HealthControllerTest`, `DevopsDemoApplicationTests`) |
| **08** | **Jenkins Console Log (Rundeck Trigger)** | Jenkins Build Console Output | HTTP 200/Success response code from Rundeck REST API call with Execution ID |
| **09** | **Rundeck Project Dashboard** | Rundeck Web Console (`http://<RUNDECK_IP>:4440`) | Project `DevOps-Automation` overview and activity stream |
| **10** | **Rundeck Jobs List** | Rundeck -> Jobs | All 5 jobs organized by groups (`Deployment`, `Operations/Application`, `Operations/Infrastructure`, etc.) |
| **11** | **Job 01: Server Health Check Execution** | Rundeck Execution View | Output showing CPU load, memory utilization, disk space, and systemd services |
| **12** | **Job 02: Application Deployment Execution** | Rundeck Execution View | Log showing artifact transfer, backup creation, symlink switch, and health check pass |
| **13** | **Job 03: Application Health Check Execution** | Rundeck Execution View | HTTP 200 response, latency (< 50ms), and JSON component health check payload |
| **14** | **Job 04: Parameterized Service Management** | Rundeck Job Form | Dropdown options for `SERVICE_NAME` (`devops-app`) and `ACTION` (`status`, `restart`) |
| **15** | **Job 05: Scheduled Maintenance Configuration** | Rundeck Job 05 Definition | Crontab icon and schedule indicator showing daily automated execution |
| **16** | **Live Application Web Interface / JSON** | Browser (`http://<RUNDECK_IP>:8080/`) | JSON output displaying `application`, `version: 1.0.0`, and `status: UP` |
| **17** | **Simulated Failure in Jenkins / Rundeck** | Jenkins or Rundeck Log | Red status banner indicating compilation/test failure or health check failure (503) |
| **18** | **Rundeck Activity & Execution History** | Rundeck -> Activity | Chronological audit log showing user triggers and automated Jenkins webhooks |
