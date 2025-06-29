pipeline {
    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/Abhikanav/amazon-clone.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Amazon \
                        -Dsonar.projectKey=Amazon'''
                }
            }
        }

        /* 
        stage('SonarQube Analysis with Token') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    withCredentials([string(credentialsId: 'Jenkins', variable: 'SONAR_TOKEN')]) {
                        sh """
                            $SCANNER_HOME/bin/sonar-scanner \
                            -Dsonar.projectName=Amazon \
                            -Dsonar.projectKey=Amazon \
                            -Dsonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }
        */

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'jenkins'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('ESLint Code Linting') {
            steps {
                sh 'npx eslint . || true'
            }
        }

        stage('Snyk Dependency Scan') {
            environment {
                SNYK_TOKEN = credentials('snyk-token')
            }
            steps {
                sh 'npm install -g snyk'
                sh 'npx snyk auth $SNYK_TOKEN'
                sh 'npx snyk test > snyk_report.txt || true'
            }
        }

        
        //stage('OWASP FS Scan') {
        //    steps {
        //        dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
        //        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        //    }
        //}
        
        //stage('OWASP FS Scan with Timeout') {
        //    steps {
        //        script {
        //            timeout(time: 2, unit: 'MINUTES') {
        //                try {
        //                    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
        //                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        //                } catch (e) {
       //                     echo "OWASP FS Scan skipped or timed out: ${e.getMessage()}"
        //                }
        //            }
        //        }
        //    }
     //    }
       
        stage('Trivy File System Scan') {
            steps {
                sh 'trivy fs . > trivyfs.txt'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh 'docker build -t amazon-clone .'
                        sh 'docker tag amazon-clone abhikmgr/amazon-clone:latest'
                        sh 'docker push abhikmgr/amazon-clone:latest'
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image abhikmgr/amazon-clone:latest > trivyimage.txt'
            }
        }

        stage('Deploy to Container') {
            steps {
                // Stop the container if it's running
                 sh 'docker stop amazon-clone || true'
               // Remove the container if it exists
                sh 'docker rm amazon-clone || true'
              // Run the new container
                sh 'docker run -d --name amazon-clone -p 3000:3000 abhikmgr/amazon-clone:latest'
            }
        }

        stage('DAST Scan with OWASP ZAP') {
            steps {
                sh '''
                    docker run --rm -v $(pwd):/zap/wrk/:rw \
                        -t owasp/zap2docker-stable zap-baseline.py \
                        -t http://localhost:3000 \
                        -g gen.conf -r zap_report.html || true
                '''
            }
        }
    }
}
