pipeline {
    agent any
    environment {
        NODE_HOME = tool name: 'NodeJS', type: 'NodeJSInstallation'
    }
    stages {
        stage('Build Node.js App') {
            steps {
                script {
                    sh "${NODE_HOME}/bin/npm install"
                    sh "${NODE_HOME}/bin/npm run build"
                }
            }
        }
        stage('Provision Infra') {
            steps {
                script {
                    dir('../infra') {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
        stage('Configure Servers') {
            steps {
                script {
                    dir('../ansible') {
                        ansiblePlaybook(
                            playbook: 'site.yml',
                            inventory: 'hosts.ini'
                        )
                    }
                }
            }
        }
        stage('Deploy App') {
            steps {
                script {
                    sh 'docker build -t my-node-app . -f Dockerfile'
                    sh 'docker run -d -p 3000:3000 my-node-app'
                }
            }
        }
    }
}
