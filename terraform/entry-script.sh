#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Install docker compose
sudo yum install docker-compose-plugin