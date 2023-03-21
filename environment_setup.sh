#!/bin/bash

# Set up the repository #
# # # # # # # # # # # # #

# update the apt package index
sudo apt-get update -y

# Update the apt package index and install packages to allow apt to use a repository over HTTPS:
echo Installing/Checking packages from list
sudo apt-get install \
    apt-transport-https -y\
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker’s official GPG key:
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg


# Set up the stable repository for Docker:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# Install Docker Engine #
# # # # # # # # # # # # #

# Update the apt package index (again)
echo updating the apt package index for the second time.
sudo apt-get update -y

# install Docker engine
echo installing Docker engine
sudo apt-get install docker -y

# # Receiving a GPG error when running apt-get update?
# # Your default umask may be incorrectly configured, preventing detection of the repository public key file. 
# # Try granting read permission for the Docker public key file before updating the package index:

# sudo chmod a+r /etc/apt/keyrings/docker.gpg
# sudo apt-get update


# Install Docker Engine, containerd, and Docker Compose.
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Start the Docker service
sudo systemctl start docker

# Enable the Docker service to start on boot
sudo systemctl enable docker

# Add the current user to the docker group
sudo usermod -aG docker $USER

# Restart the Docker daemon
sudo service docker restart

# Apply the changes to the current shell session
newgrp docker

# Install rabbitmq as a Docker container
sudo docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management

# The default ports for RabbitMQ: 5672, RabbitMQ Management UI: 15672, and Redis: 6379,

# Install redis as a Docker container
sudo docker run -d --name redis -p 6379:6379 redis:latest

# Install Prometheus as a Docker container
# -v for mount the /etc/prometheus/ directory from the host machine to the Docker container when running the container.
sudo docker run -d -p 9090:9090 -v /etc/prometheus:/etc/prometheus prom/prometheus

# Configure Prometheus to monitor RabbitMQ and Redis
sudo mkdir /etc/prometheus/
echo "
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'rabbitmq'
    static_configs:
      - targets: ['rabbitmq:15672']
    metrics_path: /api/metrics
    params:
      vhost: '/'
    scheme: http
    basic_auth:
      username: guest
      password: guest

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
    metrics_path: /
    scheme: http
EOF"  | sudo tee /etc/prometheus/prometheus.yml > /dev/null

# Restart Prometheus for the changes to take effect
sudo docker restart prometheus

# Generate a random password for Prometheus
PROMETHEUS_PASSWORD=$(openssl rand -base64 32)
echo "Prometheus password: $PROMETHEUS_PASSWORD"

# Save the Prometheus password to a file
echo $PROMETHEUS_PASSWORD | sudo tee /etc/prometheus/prometheus_password.txt > /dev/null

# Inform the user about the password file location
echo "Prometheus password is stored in /etc/prometheus/prometheus_password.txt"

# Create a Dockerfile to build a custom Prometheus container with the generated password
cat <<EOF | sudo tee Dockerfile > /dev/null
FROM prom/prometheus

COPY prometheus_password.txt /etc/prometheus/

CMD sed -i "s/PASSWORD/$(cat /etc/prometheus/prometheus_password.txt)/g" /etc/prometheus/prometheus.yml && prometheus --config.file=/etc/prometheus/prometheus.yml
EOF

# Build the custom Prometheus container
sudo docker build -t prometheus-custom .

# start the custom Prometheus container
sudo docker run -d --name prometheus-custom -p 9090:9090 prometheus-custom

# Clean up
sudo rm -rf Dockerfile

# Exit with Success
exit 0