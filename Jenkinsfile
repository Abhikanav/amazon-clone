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
                git branch: 'main', url: 'https https://github.com/Abhikanav/amazon-clone.git'
            }
        }
        //stage('SonarQube Analysis') {
        //    steps {
        //        withSonarQubeEnv('sonar-server') {
        //            sh '''$SCANNER_HOME/bin/sonar-scanner \
        //            -Dsonar.projectName=Amazon \
        //            -Dsonar.projectKey=Amazon'''
        //        }
        //    }
       // } 
         stage('SonarQube Analysis') {
           steps {
              withSonarQubeEnv('sonar-server') {
                   withCredentials([string(credentialsId: 'Jenkins', variable: 'SONAR_TOKEN')]) {
                       sh '''
                           $SCANNER_HOME/bin/sonar-scanner \
                           -Dsonar.projectName=Amazon \
                           -Dsonar.projectKey=Amazon \
                           -Dsonar.login=$SONAR_TOKEN
                      '''
                    }
                }
            }
       }
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
        stage('OWASP FS Scan') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
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
                sh 'docker run -d --name amazon-clone -p 3000:3000 abhikmgr/amazon-clone:latest'
            }
        }
    }
}
