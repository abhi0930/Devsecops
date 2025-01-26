# Jenkins Pipeline Documentation

This document provides a detailed explanation of the Jenkinsfile, including the purpose and functionality of every component.

---

## Overview of Jenkins Pipeline

A Jenkins Pipeline automates software development processes, combining build, test, and deployment stages. This declarative pipeline performs tasks including code analysis, dependency scanning, container security, and deployment using Docker.

### Pipeline Structure

```groovy
pipeline {
    agent any
    environment {
        // Environment variables for tools and configurations
    }
    stages {
        // Individual stages of the pipeline
    }
    post {
        // Cleanup and final steps
    }
}
```

### Key Components

1. **`agent any`**
   - Specifies the Jenkins agent (node) where the pipeline will run.
   - `any` means it can execute on any available node.

2. **`environment`**
   - Defines variables accessible across the pipeline.
   - Example:
     ```groovy
     environment {
         SONAR_HOME = tool "sonar" // Path to SonarQube tool
         DOCKER_CREDENTIALS_ID = 'dckr_pat_example_id' // Docker credentials ID
         ZAP_PATH = '/path/to/zap.sh' // Path to OWASP ZAP tool
         ZAP_API_KEY = 'example_api_key' // OWASP ZAP API Key
         ZAP_PORT = '8081' // OWASP ZAP server port
     }
     ```

3. **`stages`**
   - Contains logical steps of the pipeline.
   - Each stage runs sequentially and may have one or more steps.

---

## Detailed Explanation of Stages

### 1. Clone Code from GitHub

```groovy
stage("Clone Code from GitHub") {
    steps {
        git url: "https://github.com/abhi0930/Devsecops.git", branch: "main"
    }
}
```
- **Purpose**: Fetch the codebase from the GitHub repository.
- **Key Commands**:
  - `git`: Jenkins step for Git operations.
  - `url`: Specifies the repository URL.
  - `branch`: Indicates the branch to clone.

### 2. Trufflehog Secret Scan

```groovy
stage('trufflehog3') {
    steps {
        sh 'trufflehog3 . -f json -o truffelhog_output.json || true'
        archiveArtifacts artifacts: 'truffelhog_output.json', fingerprint: true
    }
}
```
- **Purpose**: Scans the codebase for exposed secrets.
- **Commands**:
  - `sh`: Executes shell commands.
  - `archiveArtifacts`: Archives the output file for inspection.

### 3. SonarQube Quality Analysis

```groovy
stage("SonarQube Quality Analysis") {
    steps {
        withSonarQubeEnv("sonar") {
            sh "$SONAR_HOME/bin/sonar-scanner -Dsonar.projectName=cdac-project -Dsonar.projectKey=cdac-project"
        }
    }
}
```
- **Purpose**: Runs static code analysis with SonarQube.
- **Commands**:
  - `withSonarQubeEnv`: Configures SonarQube environment.
  - `sh`: Executes the Sonar scanner with project-specific parameters.

### 4. OWASP Dependency Check

```groovy
stage("OWASP Dependency Check") {
    steps {
        dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'dc'
        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
    }
}
```
- **Purpose**: Scans dependencies for known vulnerabilities.
- **Commands**:
  - `dependencyCheck`: Runs OWASP Dependency Check.
  - `dependencyCheckPublisher`: Publishes the generated report.

### 5. SonarQube Quality Gate

```groovy
stage("Sonar Quality Gate Scan") {
    steps {
        timeout(time: 5, unit: "MINUTES") {
            waitForQualityGate abortPipeline: false
        }
    }
}
```
- **Purpose**: Waits for SonarQube’s quality gate result.
- **Commands**:
  - `waitForQualityGate`: Blocks execution until the quality gate result is available.

### 6. Snyk Vulnerability Scan

```groovy
stage('Snyk') {
    steps {
        script {
            dir('frontend') {
                snykSecurity(
                    snykInstallation: 'snyk',
                    snykTokenId: 'example_token_id',
                    failOnIssues: false
                )
            }
        }
    }
}
```
- **Purpose**: Identifies vulnerabilities in the project using Snyk.

### 7. Deploy Using Docker Compose

```groovy
stage("Deploy using Docker Compose") {
    steps {
        sh "docker-compose up -d"
    }
}
```
- **Purpose**: Deploys the application using Docker Compose.
- **Commands**:
  - `docker-compose up -d`: Starts containers in detached mode.

### 8. Push Docker Images

```groovy
stage('Push Docker Image') {
    steps {
        script {
            withDockerRegistry(credentialsId: 'example_registry_id', toolName: 'docker') {
                sh "docker tag devsecops_backend:latest example_repo/backend:latest"
                sh "docker push example_repo/backend:latest"
                sh "docker tag devsecops_frontend:latest example_repo/frontend:latest"
                sh "docker push example_repo/frontend:latest"
            }
        }
    }
}
```
- **Purpose**: Tags and pushes Docker images to a remote registry.

### 9. Trivy File System Scan

```groovy
stage("Trivy") {
    steps {
        sh "trivy fs --format table -o trivy-fs-report.html ."
        archiveArtifacts allowEmptyArchive: true, artifacts: 'trivy-fs-report.html', fingerprint: true
    }
}
```
- **Purpose**: Scans the filesystem for vulnerabilities using Trivy.

### 10. Container Security (Grype)

```groovy
stage('Container Security') {
    steps {
        script {
            def images = [
                ["name": "example_repo/backend", "path": "1"],
                ["name": "example_repo/frontend", "path": "2"]
            ]
            for (img in images) {
                try {
                    sh "grype ${img.name} > ${img.path}_grype.txt"
                    archiveArtifacts allowEmptyArchive: true, artifacts: "${img.path}_grype.txt", fingerprint: true
                    def vulnerabilities = readFile("${img.path}_grype.txt")
                    if (vulnerabilities.contains('vulnerable')) {
                        error("Vulnerabilities found in ${img.name}!")
                    }
                } catch (Exception e) {
                    echo "Grype scan failed: ${e.message}"
                    currentBuild.result = 'UNSTABLE'
                } finally {
                    sh "rm -rf ${img.path}_grype.txt"
                }
            }
        }
    }
}
```
- **Purpose**: Scans container images for vulnerabilities using Grype.

---

## Post-Execution Actions

### `post` Block

```groovy
post {
    always {
        script {
            sh 'docker-compose down'
        }
        cleanWs()
    }
}
```
- **Purpose**: Defines cleanup actions executed regardless of pipeline success or failure.
- **Commands**:
  - `docker-compose down`: Stops and removes containers.
  - `cleanWs()`: Cleans up the Jenkins workspace.

---

## Summary

This Jenkinsfile demonstrates a complete CI/CD pipeline for:
- Code cloning.
- Security scanning (Trufflehog, SonarQube, OWASP Dependency Check, Snyk, Trivy, Grype).
- Application deployment using Docker Compose.
- Docker image management (tagging and pushing).
- Post-execution cleanup.

The pipeline integrates essential DevSecOps practices, ensuring high-quality and secure software deployment.

