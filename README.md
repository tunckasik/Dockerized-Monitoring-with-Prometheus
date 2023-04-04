# Dockerized Monitoring with Prometheus

# Terraform AWS EC2 Instance with VPC, Security Group, and Custom Applications

This Terraform configuration sets up an AWS EC2 instance within a custom VPC and configures a security group. It also provisions a file to the EC2 instance and establishes an SSH connection. The instance will have RabbitMQ, Redis, and Prometheus installed and configured using Docker containers.

## Prerequisites

- Terraform installed (v1.0.0 or later)
- AWS account and credentials configured (AWS CLI or environment variables)

## Resources Created

- AWS VPC
- AWS Subnet
- AWS Security Group
- AWS EC2 Instance

## Variables

- `region`: AWS region where resources will be created.
- `ami_type`: The Amazon Machine Image (AMI) ID for the EC2 instance.
- `instance_type`: The EC2 instance type (e.g., t2.micro).
- `ssh_key_name`: The name of the SSH key pair for the EC2 instance.
- `ec2_tag`: The tag for the EC2 instance.
- `source_file_path`: The local path of the file to be provisioned on the EC2 instance.
- `user_type`: The user type for the SSH connection (e.g., ec2-user or ubuntu).
- `ssh_private_key_path`: The path to the directory containing the private SSH key file.
- `prefix`: The prefix for naming resources.

## Usage

1. Setting up Terraform AWS EC2 Instance

- Clone repository --> Create terraform.tfvars file --> Save setup_script.sh --> Initialize Terraform --> Plan and apply Terraform configuration


1. Installing Monitoring Stack

- Navigate to script directory --> Make script executable (chmod +x setup.sh) --> Run the script (./setup.sh)

1. Configuring Monitoring Stack

- Modify docker run commands in the script (if needed) to change the default ports for RabbitMQ, RabbitMQ Management UI, Redis, and Prometheus

1. Cleaning Up

- For Terraform resources: Run terraform destroy
- For Docker containers: Run sudo docker stop and sudo docker rm commands for each container (rabbitmq, redis, prometheus-custom, prometheus)

## This script should do the following:

1. Update the apt package index and install necessary dependencies.
2. Add Docker's official GPG key and set up the stable repository for Docker.
3. Install Docker engine, start the Docker service, and enable it to start on boot.
4. Install rabbitmq, redis, Prometheus, and Prometheus database as Docker containers.
5. Configure Prometheus to monitor rabbitmq, redis, and itself.
6. Generate a random password for Prometheus, write it to a file, and inform the user about the file location.
7. Create a Dockerfile to build a custom Prometheus container with the generated password.
8. Build and start the custom Prometheus container.
9. Clean up the Dockerfile.
10. Exit with success.

## Diagram

+-------------------------+
|       AWS Account       |
|                         |
| +---------------------+ |
| |      AWS VPC        | |
| |                     | |
| | +-----------------+ | |
| | |    AWS Subnet   | | |
| | +-----------------+ | |
| +---------------------+ |
|                         |
| +---------------------+ |
| | AWS Security Group  | |
| +---------------------+ |
+-------------------------+
               |
               |
               v
+-------------------------+
|    AWS EC2 Instance     |
|                         |
| +---------------------+ |
| |     RabbitMQ        | |
| |  (Docker container) | |
| +---------------------+ |
|                         |
| +---------------------+ |
| |       Redis         | |
| |  (Docker container) | |
| +---------------------+ |
|                         |
| +---------------------+ |
| |     Prometheus      | |
| |  (Custom container) | |
| +---------------------+ |
+-------------------------+