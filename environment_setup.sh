#!/bin/bash

# Set up the Docker & Docker Compose #
# # # # # # # # # # # # # # # # # # ##

# update the apt package index
sudo apt update -y

# Update the apt package index and install packages to allow apt to use a repository over HTTPS:
echo Installing/Checking packages from list
sudo apt install \
    apt-transport-https -y\
    ca-certificates \
    curl \
    gnupg \
    software-properties-common \
    lsb-release

# Add Docker’s official GPG key:
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg


# Set up the stable repository for Docker:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-cache policy docker-ce

# Install Docker Engine #
# # # # # # # # # # # # #

# Update the apt package index (again)
echo updating the apt package index for the second time.
sudo apt update -y

# install Docker engine
echo installing Docker engine
sudo apt install docker -y

# # Receiving a GPG error when running apt-get update?
# # Your default umask may be incorrectly configured, preventing detection of the repository public key file. 
# # Try granting read permission for the Docker public key file before updating the package index:

# sudo chmod a+r /etc/apt/keyrings/docker.gpg
# sudo apt update


# Install Docker Engine, containerd.
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Start the Docker service
sudo systemctl start docker

# Enable the Docker service to start on boot
sudo systemctl enable docker

# Restart the Docker daemon
sudo service docker restart

# # Apply the changes to the current shell session
# newgrp docker
# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# To be able to generate a password
sudo apt install apache2-utils -y

# Password Generating #
# # # # # # # # # # # #
password=`openssl rand -base64 32`
passwordHashed=`echo ${password} | htpasswd -inBC 10 "" | tr -d ':\n'`
echo "${password}"

cat << EOF >> ./web.yml
basic_auth_users:
  prometheus: "${passwordHashed}"

EOF


#  Prometheus Config  #
# # # # # # # # # # # #

cat << "EOF" > prometheus.yml
global:
  scrape_interval:     15s
  evaluation_interval: 15s
  external_labels:
      monitor: 'codelab-monitor'

scrape_configs:

  - job_name: 'rabbitmq'
    metrics_path: '/metrics'
    static_configs:
    - targets: ['rabbitmq_exporter:9090']
    
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: redis-exporter
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'influxdb'
    static_configs:
      - targets: ['influxdb:8086']

remote_write:
  - url: "http://localhost:9201/write"

remote_read:
  - url: "http://localhost:9201/read"

EOF


#  Docker Compose #
# # # # # # # # # # 

cat << "EOF" > docker-compose.yml
version: '3'
services:
  rabbitmq:
    image: rabbitmq:3.6.4-management
    hostname: rabbitmq
    expose:
      - "9090"
    ports:
      - "4369:4369"
      - "5671:5671"
      - "5672:5672"
      - "15672:15672"
      - "25672:25672"

  rabbitmq_exporter:
    image: kbudde/rabbitmq-exporter
    depends_on:
      - "rabbitmq"
    ports:
      - "9999:9090"
    environment:
      RABBIT_URL: "http://rabbitmq:15672"
      RABBIT_USER: "guest"
      RABBIT_PASSWORD: "guest"
      PUBLISH_PORT: "9090"
      OUTPUT_FORMAT: "JSON"
      LOG_LEVEL: "debug"

  redis:
    image: "bitnami/redis:latest"
    ports:
      - 6379:6379
    environment:
      - REDIS_REPLICATION_MODE=master
      - REDIS_PASSWORD=my_master_password

  redis-exporter:
    image: oliver006/redis_exporter
    ports:
      - 9121:9121
    restart: unless-stopped
    environment:
      REDIS_ADDR: "redis:6379"
      REDIS_USER: null
      REDIS_PASSWORD: my_master_password
    
  influxdb:              # (prometheus' remote time-series database)
    image: influxdb
    ports:
      - 8086:8086
    volumes:
      - ./:/var/lib/influxdb
  
  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - 9100:9100
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro

  remotestorageadapter:
    image: gavind/prometheus-remote-storage-adapter:1.0
    ports:
      - 9201:9201
    command: ['-influxdb-url=http://localhost:8086', '-influxdb.database=prometheus', '-influxdb.retention-policy=autogen']
    depends_on:
      - influxdb

  prometheus:
    image: "prom/prometheus"
    command: 
      - '--web.config.file=/etc/prometheus/web.yml'
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./web.yml:/etc/prometheus/web.yml
    ports:
      - 9090:9090
    depends_on:
      - rabbitmq_exporter
      - redis-exporter
      - influxdb

  grafana:
    image: grafana/grafana:7.5.7
    ports:
      - 3000:3000
    restart: unless-stopped
    volumes:
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources

    depends_on:
      - prometheus
EOF

sudo docker-compose -f docker-compose.yml up -d

echo "${password}" > password.txt

echo "username:prometheus, you can get your password at password.txt."
