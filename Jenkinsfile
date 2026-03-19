pipeline {
    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

  environment {
    SCANNER_HOME = tool 'sonar-scanner'
    AZURE_CREDS = credentials('AZURE_CRED_ID')
    ARM_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    TF_VAR_client_id     = "${AZURE_CREDS_USR}"
    TF_VAR_client_secret = "${AZURE_CREDS_PSW}"
    TF_VAR_tenant_id     = credentials('AZURE_TENANT_ID')
    DEP_CHECK_HOME = tool 'dependency-check'
  }

    stages {
        stage('clean workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main',
                    credentialsId: 'Git',
                    url: 'https://github.com/sirisha-k83/N-clone-Devsecops-v2.git'
            }
        }

        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Netflix \
                        -Dsonar.projectKey=Netflix
                    """
                }
            }
        }

        stage("quality gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: true, credentialsId: 'Sonar-token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh "npm install"
                sh 'yarn install'
            }
        }

      stage('Dependency Check') {
        steps {
        withCredentials([string(credentialsId: 'API', variable: 'NVD_API_KEY')]) {
             sh """
                ${DEP_CHECK_HOME}/bin/dependency-check.sh \
                --project "NetflixClone" \
                --scan . \
                --format HTML \
                --nvdApiKey $NVD_API_KEY \
                --disableYarnAudit \
                --disableNodeAudit \
                --exclude '**/node_modules/**'
            """
        }
    }
}

        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }

        stage("Docker Build & Push") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh "docker build -t netflix ."
                        sh "docker tag netflix sirishak83/netflix:latest"
                        sh "docker push sirishak83/netflix:latest"
                    }
                }
            }
        }

        stage("TRIVY Image Scan") {
            steps {
                sh "trivy image sirishak83/netflix:latest > trivyimage.txt"
            }
        }

        stage('Deploy to container') {
            steps {
                sh """
                    docker run -d --name netflix-container -p 8081:80 sirishak83/netflix:latest
                """
            }
        }

         stage('Terraform Init') {
           steps {
                sh 'terraform init'
            }
        }
        stage('Terraform Plan & Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }        
  
       stage('Deploy to AKS') {
         steps {
           script {
              withCredentials([
                usernamePassword(credentialsId: 'AZURE_CRED_ID', usernameVariable: 'AZ_CLIENT_ID', passwordVariable: 'AZ_CLIENT_SECRET'),
                string(credentialsId: 'AZURE_TENANT_ID', variable: 'AZ_TENANT_ID')
            ]) {
                sh """
                    az login --service-principal -u "${AZ_CLIENT_ID}" -p "${AZ_CLIENT_SECRET}" -t "${AZ_TENANT_ID}"
                    
                    az aks get-credentials --resource-group AZB48SLB --name netflix-cluster --overwrite-existing

                    cd Kubernetes
                    kubectl apply -f deployment.yml
                    kubectl apply -f service.yml
                    kubectl apply -f node-service.yaml
                """
            }
         }
      }
     }
 }
}

