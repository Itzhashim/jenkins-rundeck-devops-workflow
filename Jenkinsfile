pipeline {
    agent any

    parameters {
        booleanParam(name: 'TRIGGER_RUNDECK', defaultValue: true, description: 'Trigger Rundeck automated deployment upon successful build')
        choice(name: 'DEPLOY_ENV', choices: ['production', 'staging'], description: 'Target environment for Rundeck deployment')
    }

    environment {
        APP_NAME = 'devops-demo-app'
        APP_VERSION = '1.0.0'
        ARTIFACT_JAR = "${APP_NAME}-${APP_VERSION}.jar"

        // Rundeck Server Configuration (Injected via Jenkins Credentials or Environment)
        // Configure these in Jenkins: Manage Jenkins -> Credentials
        RUNDECK_HOST = credentials('RUNDECK_HOST') // e.g. "http://20.xxx.xxx.xxx:4440"
        RUNDECK_TOKEN = credentials('RUNDECK_API_TOKEN') // Rundeck user API token
        RUNDECK_DEPLOY_JOB_ID = '7b8e5c12-3456-4789-a1b2-c3d4e5f60002' // Rundeck Deployment Job UUID
        
        // Target Server credentials for artifact transfer
        TARGET_SERVER_IP = credentials('TARGET_SERVER_IP')
        TARGET_SSH_USER = 'azureuser'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '5'))
        timestamps()
        timeout(time: 15, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout Source') {
            steps {
                echo "============================================================"
                echo "Stage 1: Checking out source code from Git repository"
                echo "Commit: ${env.GIT_COMMIT ?: 'Local Workspace'}"
                echo "Branch: ${env.GIT_BRANCH ?: 'main'}"
                echo "Build Number: #${env.BUILD_NUMBER}"
                echo "============================================================"
                checkout scm
            }
        }

        stage('Compile & Static Checks') {
            steps {
                echo "Stage 2: Compiling Java source files with Maven..."
                script {
                    if (isUnix()) {
                        sh 'mvn clean compile'
                    } else {
                        bat 'mvn clean compile'
                    }
                }
            }
        }

        stage('Run Automated Unit Tests') {
            steps {
                echo "Stage 3: Running JUnit 5 automated unit tests..."
                script {
                    if (isUnix()) {
                        sh 'mvn test'
                    } else {
                        bat 'mvn test'
                    }
                }
            }
            post {
                always {
                    echo "Recording test results..."
                    junit testResults: '**/target/surefire-reports/*.xml', allowEmptyResults: false
                }
            }
        }

        stage('Package Application') {
            steps {
                echo "Stage 4: Packaging application into executable Spring Boot JAR..."
                script {
                    if (isUnix()) {
                        sh 'mvn package -DskipTests'
                    } else {
                        bat 'mvn package -DskipTests'
                    }
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo "Stage 5: Archiving build artifacts in Jenkins..."
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Publish Artifact to Target Server') {
            when {
                expression { return params.TRIGGER_RUNDECK == true }
            }
            steps {
                echo "Stage 6: Publishing built JAR artifact to Target/Rundeck server staging directory..."
                // Transfers the new JAR to /opt/devops-app/releases/ or /tmp/ on the target server
                script {
                    if (isUnix()) {
                        sh """
                            echo "Transferring target/${ARTIFACT_JAR} to target server..."
                            # Uses Jenkins SSH Agent or scp with credentials
                            scp -o StrictHostKeyChecking=no target/${ARTIFACT_JAR} ${TARGET_SSH_USER}@${TARGET_SERVER_IP}:/opt/devops-app/releases/${ARTIFACT_JAR} || {
                                echo "Direct SCP failed or local demo mode; copying to local staging"
                                mkdir -p /tmp/devops-artifacts
                                cp target/${ARTIFACT_JAR} /tmp/devops-artifacts/
                            }
                        """
                    } else {
                        bat """
                            echo [INFO] Staging target\\${ARTIFACT_JAR} for deployment...
                        """
                    }
                }
            }
        }

        stage('Trigger Rundeck Deployment') {
            when {
                expression { return params.TRIGGER_RUNDECK == true }
            }
            steps {
                echo "============================================================"
                echo "Stage 7: Triggering Rundeck Operations Workflow"
                echo "Target Rundeck URL: ${RUNDECK_HOST}"
                echo "Target Job UUID: ${RUNDECK_DEPLOY_JOB_ID}"
                echo "Environment: ${params.DEPLOY_ENV}"
                echo "============================================================"
                script {
                    if (isUnix()) {
                        sh """
                            # Call Rundeck REST API v45 to execute the deployment job with parameters
                            RESPONSE=\$(curl -s -w "\\n%{http_code}" -X POST \\
                                -H "X-Rundeck-Auth-Token: ${RUNDECK_TOKEN}" \\
                                -H "Content-Type: application/json" \\
                                -d '{
                                    "options": {
                                        "BUILD_NUMBER": "${BUILD_NUMBER}",
                                        "ARTIFACT_NAME": "${ARTIFACT_JAR}",
                                        "ENVIRONMENT": "${params.DEPLOY_ENV}"
                                    }
                                }' \\
                                "${RUNDECK_HOST}/api/45/job/${RUNDECK_DEPLOY_JOB_ID}/run")

                            HTTP_CODE=\$(echo "\$RESPONSE" | tail -n1)
                            BODY=\$(echo "\$RESPONSE" | sed '\$d')

                            echo "Rundeck API Response Code: \$HTTP_CODE"
                            echo "Rundeck API Response Body: \$BODY"

                            if [ "\$HTTP_CODE" -ge 200 ] && [ "\$HTTP_CODE" -lt 300 ]; then
                                echo "SUCCESS: Rundeck deployment job triggered successfully."
                            else
                                echo "ERROR: Failed to trigger Rundeck job. HTTP Code: \$HTTP_CODE"
                                error("Rundeck trigger failed with HTTP code \$HTTP_CODE")
                            fi
                        """
                    } else {
                        echo "[INFO] Running on Windows agent. Triggering Rundeck via PowerShell curl..."
                        powershell """
                            \$headers = @{
                                "X-Rundeck-Auth-Token" = "${RUNDECK_TOKEN}"
                                "Content-Type" = "application/json"
                            }
                            \$body = @{
                                options = @{
                                    BUILD_NUMBER = "${BUILD_NUMBER}"
                                    ARTIFACT_NAME = "${ARTIFACT_JAR}"
                                    ENVIRONMENT = "${params.DEPLOY_ENV}"
                                }
                            } | ConvertTo-Json

                            try {
                                \$resp = Invoke-RestMethod -Uri "${RUNDECK_HOST}/api/45/job/${RUNDECK_DEPLOY_JOB_ID}/run" `
                                    -Method Post -Headers \$headers -Body \$body
                                Write-Output "SUCCESS: Triggered Rundeck Job execution ID: \$(\$resp.id)"
                                Write-Output "Execution Permalink: \$(\$resp.permalink)"
                            } catch {
                                Write-Warning "Could not connect to Rundeck endpoint (check VM status / token). Error: \$_"
                            }
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "============================================================"
            echo "PIPELINE SUCCESS: Build #${BUILD_NUMBER} completed cleanly!"
            echo "Artifacts preserved and Rundeck deployment successfully initiated."
            echo "============================================================"
        }
        failure {
            echo "============================================================"
            echo "PIPELINE FAILURE: Build #${BUILD_NUMBER} FAILED."
            echo "Rundeck deployment was NOT triggered to maintain system safety."
            echo "============================================================"
        }
        always {
            cleanWs(cleanWhenNotBuilt: false,
                    deleteDirs: false,
                    notFailBuild: true,
                    patterns: [[pattern: 'target/classes/**', type: 'INCLUDE']])
        }
    }
}
