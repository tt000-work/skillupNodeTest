pipeline {
    // Any available agent can be used to execute this pipeline
    agent any

    // Environment variables that are set for the pipeline
    environment {
        LANG = 'en_US.UTF-8'                 // Language setting for the environment
        LC_ALL = 'en_US.UTF-8'               // Locale setting
        ANSIBLE_INVENTORY = 'ips-inventory.ini' // Default Ansible inventory file name
        DOCKER_IMAGE = 'node.js-test-app'    // Base name for the Docker image
    }

    stages {
        // Stage for setting up the system environment
        stage('Setup Environment') {
            steps {
                // Shell commands to install necessary packages
                sh '''
                    // Update package lists
                    sudo apt-get update

                    // Install necessary packages if they are not already installed
                    for pkg in gnupg software-properties-common curl sshpass docker-ce nodejs npm ansible; do
                        if ! dpkg -l | grep -q $pkg; then
                            sudo apt-get install -y $pkg
                        fi
                    done

                    // Check if Docker is installed, if not, install it
                    if ! dpkg -l | grep -q docker-ce; then
                        // Add Docker's GPG key
                        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                        // Add Docker's APT repository
                        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
                        // Install Docker
                        sudo apt-get install -y docker-ce
                        // Start Docker service
                        sudo systemctl start docker
                    fi
                '''
            }
        }

        // Stage for provisioning Docker containers for different environments
        stage('Provisioning Environments') {
            steps {
                script {
                    // List of environments to provision
                    def environments = ['dev', 'int', 'prod']
                    // Image reference for the container to be run
                    def containerImage = 'tt000/remote-server1:latest'

                    // Loop through each environment to provision it
                    environments.each { environ ->
                        stage("Provisioning ${environ} environment") {
                            // Name for the Docker container based on the environment
                            def containerName = "${environ}_container"

                            // Shell commands to manage Docker containers
                            sh """
                                // Stop and remove the container if it exists
                                if [ \$(docker ps -q -f name=${containerName}) ]; then
                                    docker stop ${containerName}
                                    docker rm ${containerName}
                                fi
                                // Run a new Docker container in detached mode
                                docker run -d --name ${containerName} ${containerImage} sleep infinity
                                // Start the SSH service inside the container
                                docker exec -u 0 ${containerName} service ssh start
                            """

                            // Retrieve the IP address of the running container
                            def containerIp = sh(script: "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${containerName}", returnStdout: true).trim()
                            // Define the inventory file path for Ansible
                            def inventoryFile = "${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}"

                            // Write container's IP to the Ansible inventory file
                            writeFile file: inventoryFile, text: """
                            [${environ}]
                            ${containerIp} ansible_connection=docker
                            """
                            // Echo the contents of the inventory file for verification
                            echo "Inventory File Contents for ${environ}:\n${readFile(file: inventoryFile)}"
                        }
                    }
                }
            }
        }

        // Stage for building and deploying the application to the provisioned environments
        stage('Build and Deploy') {
            steps {
                script {
                    // List of environments for deployment
                    def environments = ['dev', 'int', 'prod']

                    // Loop through each environment to build and deploy
                    environments.each { environ ->
                        stage("Build and Deploy to ${environ} environment") {
                            // Define the inventory file for the current environment
                            def inventoryFile = "${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}"

                            // Use stored credentials for SSH access
                            withCredentials([usernamePassword(credentialsId: 'ssh', passwordVariable: 'sshPass', usernameVariable: 'sshUser')]) {
                                echo "Using inventory file: ${inventoryFile}"

                                // Run Ansible playbooks for Docker and application setup
                                sh "sudo ansible-playbook -vvvv -i ${inventoryFile} ansible/add-docker.yml"
                                sh "sudo ansible-playbook -i ${inventoryFile} ansible/${environ}-playbook.yml -vvvv"

                                // Build Docker image for the application
                                def dockerImage = docker.build("${DOCKER_IMAGE}:${environ}", '-f Dockerfile .')

                                // Use stored credentials for Docker login
                                withCredentials([usernamePassword(credentialsId: 'dockerCreds', passwordVariable: 'dockerPass', usernameVariable: 'dockerUser')]) {
                                    sh "docker login -u ${dockerUser} -p ${dockerPass}"

                                    // Tag the Docker image for pushing to the registry
                                    def imageTag = "${dockerUser}/${DOCKER_IMAGE}:${environ}"
                                    sh "docker tag ${dockerImage.imageName()} ${imageTag}"
                                    // Push the tagged image to the Docker registry
                                    sh "docker push ${imageTag}"

                                    // Run Ansible playbook to deploy the Docker image
                                    ansiblePlaybook(
                                        playbook: 'ansible/run-dockerImage.yml -vvv',
                                        inventory: inventoryFile,
                                        extraVars: [
                                            docker_image: imageTag,
                                            ansible_user: 'root',
                                        ],
                                        credentialsId: 'ssh'
                                    )

                                    // Check deployment status using Ansible
                                    def deployStatus = sh(script: "ansible -i ${inventoryFile} -m shell -a 'docker ps | grep ${DOCKER_IMAGE}:${environ}'", returnStatus: true)
                                    // If deployment failed, raise an error
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
