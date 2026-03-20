#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Install docker compose in Amazon Linux 2023 (https://docs.docker.com/compose/install/linux/#install-the-plugin-manually)

# Το user_data του Terraform τρέχει σαν root, οπότε πήγαινε και έκανε εγκατάσταση μέσα στο /root/.docker/..., 
# οπότε μετά πήγαινα να τρέξω το docker compose σαν ec2-user και δεν έβρισκε τίποτα. Οπότε δες πιο κάτω ότι το εγκαθιστώ κάπου που έχουν όλοι οι χρήστες πρόσβαση 
# DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
# mkdir -p $DOCKER_CONFIG/cli-plugins

mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v5.0.1/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose