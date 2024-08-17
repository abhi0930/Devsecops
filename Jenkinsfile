pipeline{
    agent any
    environment{
        SONAR_HOME= tool "sonar"
        DOCKER_CREDENTIALS_ID = 'dckr_pat_pE9yCHQokBQLDlvI1s_Z_fzOf8Q'
        //TARGET_URL = 'https://medium.com/edureka/nagios-tutorial-e63e2a744cc8'
        ZAP_PATH = '/var/lib/jenkins/ZAP_2.15.0/zap.sh'
        ZAP_API_KEY = '33ufgoa3ig6r9sr2mmtcch3mk4'
        ZAP_PORT = '8081'
    }
    stages{
        
        stage("Clone Code from GitHub"){
            steps{
                git url:"https://github.com/abhi0930/Devsecops.git", branch: "main"
            }
        }
        
        stage ('trufflehog3') {
            steps {
                sh 'trufflehog3 . -f json  -o truffelhog_output.json || true'
                archiveArtifacts artifacts: 'truffelhog_output.json', fingerprint: true
            }
        }
        
        stage("SonarQube Quality Analysis"){
            steps{
                 withSonarQubeEnv("sonar"){
                     sh "$SONAR_HOME/bin/sonar-scanner -Dsonar.projectName=cdac-project -Dsonar.projectKey=cdac-project"
                     
                 }
            }
        }
        
        stage("OWASP Dependency Check"){
            steps{
                 dependencyCheck additionalArguments: '--scan ./', odcInstallation:'dc'
                 dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        
        stage("Sonar Quality Gate Scan"){
            steps{
                timeout(time: 5, unit: "MINUTES"){
                    waitForQualityGate abortPipeline: false 
                }
            }
        }
        
        stage('Snyk') {
            steps {
                script{
                    dir('frontend'){
                    snykSecurity(
                        snykInstallation: 'snyk',
                        snykTokenId: 'e6979a44-0e50-40fb-8b0b-de1f860ef7e8',
                        failOnIssues: false,
                    )
                    }
                }    
            }
        }
        
        stage("Deploy using Docker Compose"){
            steps{
                sh "docker-compose up -d"
            }
        }
        
       
        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: '6f4e297d-9998-4d23-9ea4-3fc8e9433e9e', toolName: 'docker') {
                
                            
                            sh "docker tag devsecops_backend:latest ditiss2024/devsecops_backend:latest"
                            sh "docker push ditiss2024/devsecops_backend:latest"
                            //sh 'docker build -t ditiss2024/image$i:latest .'
                            sh "docker tag devsecops_frontend:latest ditiss2024/devsecops_frontend:latest"
                            sh "docker push ditiss2024/devsecops_frontend:latest"
                    }
                }
            }
        }
        
        stage("Trivy"){
            steps{
                 sh "trivy fs --format table -o trivy-fs-report.html ."
                  archiveArtifacts allowEmptyArchive: true, artifacts: 'trivy-fs-report.html', fingerprint: true, followSymlinks: false, onlyIfSuccessful: true
            }
        }
        
        stage('Container Security') {
            steps {
                script {
                    // List of built images to scan
                    def images = [
                        ["name": "ditiss2024/devops_backend", "path": "1"],
                        ["name": "ditiss2024/deveops_frontend", "path": "2"]
                    ]
                    
                    for (img in images) {
                        try {
                            // Run the Grype scan and redirect output to grype.txt
                            sh "grype ${img.name} > ${img.path}_grype.txt"
                
                            // Archive the grype output regardless of success
                            archiveArtifacts allowEmptyArchive: true, artifacts: "${img.path}_grype.txt", fingerprint: true, followSymlinks: false
                            
                            // Read the vulnerabilities from the output file
                            def vulnerabilities = readFile("${img.path}_grype.txt")
                            echo "Grype Scan Output:\n${vulnerabilities}"
                            
                            // Check if vulnerabilities were found and fail the build if necessary
                            if (vulnerabilities.contains('vulnerable')) {
                                error("Vulnerabilities found in ${img.name}!")
                            }
                        } catch (Exception e) {
                            // Catch the exception and echo the error message
                            echo "Grype scan failed: ${e.message}"
                            
                            // Archive the output even if the Grype command fails
                            archiveArtifacts allowEmptyArchive: true, artifacts: "${img.path}_grype.txt", fingerprint: true, followSymlinks: false
                            
                            // Mark the build as unstable
                            currentBuild.result = 'UNSTABLE'
                        } finally {
                            // Cleanup the output file after processing
                            sh "rm -rf ${img.path}_grype.txt"
                        }
                    }
                }
            }
        }
        
       /* stage('Kubernetes'){
             steps {
                sh 'echo "Deploying the application"'
            }
        }*/
        stage('OWASPZAP') {
            steps {
                sh 'echo "Deploying the application"'
            /*steps {
                script{
                    sh zap-cli start --start-options -daemon
                    sh zap-cli open-url ${TARGET_URL}
                    sh zap-cli spider ${TARGET_URL}
               
                    sh zap-cli -v report -f html -o report-zap-cli-jenkins.html
                    sh zap-cli shutdown
                } 
                archiveArtifacts allowEmptyArchive: true, artifacts: 'report-zap-cli-jenkins.html', fingerprint: true, followSymlinks: false, onlyIfSuccessful: true
                //sh ' rm -rf report-zap-cli-jenkins.html' */
                
            }
        }
        
    }
    
    post {
        always {
            script {
                sh 'docker-compose down'
            }
            cleanWs()
        }
    }
}
