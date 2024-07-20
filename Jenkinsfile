pipeline {
    agent any

    environment {
        LANG = 'en_US.UTF-8'
        LC_ALL = 'en_US.UTF-8'
        ANSIBLE_INVENTORY = 'ips-inventory.ini'
        DOCKER_IMAGE = 'node.js-test-app'
    }

    stages {
        stage('Setup Environment') {
            steps {
                sh '''
                    # Update the package list
                    sudo apt-get update

                    # Check if gnupg is installed, if not, install it
                    if ! dpkg -l | grep -q gnupg; then
                        sudo apt-get install -y gnupg
                    fi

                    # Check if software-properties-common is installed, if not, install it
                    if ! dpkg -l | grep -q software-properties-common; then
                        sudo apt-get install -y software-properties-common
                    fi

                    # Check if curl is installed, if not, install it
                    if ! dpkg -l | grep -q curl; then
                        sudo apt-get install -y curl
                    fi

                    # Check if sshpass is installed, if not, install it
                    if ! dpkg -l | grep -q sshpass; then
                        sudo apt-get install -y sshpass
                    fi

                    # Add Docker GPG key and repository if Docker is not installed
                    if ! dpkg -l | grep -q docker-ce; then
                        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
                        sudo apt-get install -y docker-ce
                        sudo systemctl start docker
                    fi

                    # Check if nodejs is installed, if not, install it
                    if ! dpkg -l | grep -q nodejs; then
                        sudo apt-get install -y nodejs
                    fi

                    # Check if npm is installed, if not, install it
                    if ! dpkg -l | grep -q npm; then
                        sudo apt-get install -y npm
                    fi

                    # Check if ansible is installed, if not, install it
                    if ! dpkg -l | grep -q ansible; then
                        sudo apt-get install -y ansible
                    fi
                '''
            }
        }

        stage('Provisioning environments') {
            steps {
                script {
                    def environments = ['dev', 'int', 'prod']
                    for (environ in environments) {
                        stage("Provisioning ${environ} environment") {
                            def containerName = "${environ}_container"
                            def containerImage = 'tt000/remote-server1:latest'  //TODO:Add Name of your custom image

                            // Stop and remove old containers with the same name
                            sh """
                                if [ \$(docker ps -q -f name=${containerName}) ]; then
                                    docker stop ${containerName}
                                    docker rm ${containerName}
                                fi
                            """
                            
                            // Run a new Docker container
                            sh "docker run -d --name ${containerName} ${containerImage} sleep infinity"
                            
                            // Retrieve the container IP address
                            def containerIp = sh(script: "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${containerName}", returnStdout: true).trim()

                            // Start SSH on Container
                            sh "docker exec -u 0 ${containerName} service ssh start"
                            
                            // Remove any existing inventory file for this environment
                            sh "rm -f ${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}"

                            // Write the inventory file
                            writeFile file: "${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}", text: """
                            [${environ}]
                            ${containerIp} ansible_connection=docker
                            """
                        }
                    }
                }
            }
        }
        stage('Build and Deploy') {
            steps {
                script {
                    // Define the environments
                    def environments = ['dev', 'int', 'prod']

                    // Loop through each environment
                    environments.each { environ ->
                        stage("Build and Deploy to ${environ} environment") {
                            // Use SSH credentials
                            withCredentials([usernamePassword(credentialsId: 'ssh', passwordVariable: 'sshPass', usernameVariable: 'sshUser')]) {
                                // Display the inventory file
                                sh "cat ${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}"

                                // Install Docker on the remote servers using Ansible
                                sh "ansible-playbook -i ${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY} ansible/add-docker.yml"

                                // Build Docker image for the current environment
                                def dockerImage = docker.build("${DOCKER_IMAGE}:${environ}", '-f Dockerfile .')

                                // Push Docker image to Docker registry
                                withCredentials([usernamePassword(credentialsId: 'dockerCreds', passwordVariable: 'dockerPass', usernameVariable: 'dockerUser')]) {
                                    // Login to Docker registry
                                    sh "docker login -u ${dockerUser} -p ${dockerPass}"

                                    // Tag the Docker image
                                    def imageTag = "${dockerUser}/${DOCKER_IMAGE}:${environ}"
                                    sh "docker tag ${dockerImage.imageName()} ${imageTag}"

                                    // Push the Docker image to the registry
                                    sh "docker push ${imageTag}"

                                    // Deploy the Docker image using Ansible
                                    ansiblePlaybook(
                                        playbook: 'ansible/run-dockerImage.yml',
                                        inventory: "${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}",
                                        extraVars: [
                                            docker_image: imageTag
                                        ],
                                        credentialsId: 'ssh'
                                    )

                                    // Verify deployment
                                    def deployStatus = sh(script: "ansible -i ${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY} -m shell -a 'docker ps | grep ${DOCKER_IMAGE}:${environ}'", returnStatus: true)
                                    if (deployStatus != 0) {
                                        error "Deployment to ${environ} environment failed"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
