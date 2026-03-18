#!/usr/bin/env bash

export IMAGE=$1
export DOCKER_USER=$2
export DOCKER_PWD=$3

# Το ec2-instance πρέπει να κάνει docker login ώστε να μπορεί να κάνει pull τα images από το private Docker hub
echo $DOCKER_PWD | docker login -u $DOCKER_USER --password-stdin
docker compose -f docker-compose.yaml up --detach
echo "success"