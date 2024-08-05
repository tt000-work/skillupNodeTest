# SkillUp Node Test CI/CD Pipeline Project

This project demonstrates an end-to-end CI/CD pipeline setup for building and deploying applications using Jenkins, Maven, Node.js, Ansible, Terraform, and Docker. The pipeline automates the entire process, from setting up the environment to provisioning infrastructure and deploying the application.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup](#setup)
  - [Environment Setup](#environment-setup)
  - [Terraform Configuration](#terraform-configuration)
  - [Ansible Playbooks](#ansible-playbooks)
  - [Jenkins Pipeline](#jenkins-pipeline)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites
- **Git**: Version control system to manage the project repository.
- **Docker**: Containerization platform to run isolated environments.
- **Jenkins**: Continuous Integration and Continuous Delivery server.
- **Terraform**: Infrastructure as Code (IaC) tool to provision infrastructure.
- **Ansible**: Configuration management tool to manage and configure servers.
- **Maven**: Build automation tool for Java projects.
- **Node.js**: JavaScript runtime for building scalable network applications.

  ## Setup

### Environment Setup
1. **Clone the repository:**
    ```sh
    git clone https://github.com/tt000-work/skillupNodeTest.git
    cd skillupNodeTest
    ```

2. **Set up Docker containers for remote Ubuntu servers:**
    Follow the instructions to create and start Docker containers with Ubuntu servers.

3. **Install required tools:**
    Ensure Docker, Jenkins, Terraform, Ansible, Maven, and Node.js are installed on your system.

### Terraform Configuration
1. **Initialize Terraform:**
    ```sh
    cd terraform
    terraform init
    ```

2. **Provision infrastructure:**
    ```sh
    terraform apply
    ```
    Review the plan and confirm to provision the infrastructure.

### Ansible Playbooks
1. **Run Ansible playbooks to configure servers:**
    ```sh
    cd ansible/playbooks
    ansible-playbook setup.yml
    ansible-playbook deploy.yml
    ```

### Jenkins Pipeline
1. **Set up Jenkins:**
    - Install Jenkins on your machine or server.
    - Configure Jenkins to use Docker, Maven, and Node.js.

2. **Create a Jenkins pipeline:**
    - Open Jenkins and create a new pipeline.
    - Use the `Jenkinsfile` from the repository to define the pipeline.

## Usage
- **Build and deploy the application:**
    Trigger the Jenkins pipeline to build and deploy the application to the specified environments (dev, int, prod).

- **Access the application:**
    The application will be accessible via URLs for the respective environments.
