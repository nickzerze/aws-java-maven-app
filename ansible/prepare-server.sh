#!/usr/bin/env bash

apt update
apt install ansible -y
apt install python3-pip -y
#pip3 install boto3 botocore
apt install python3-boto3 -y
apt install python3-botocore -y

# export AWS_ACCESS_KEY_ID=$1
# export AWS_SECRET_ACCESS_KEY=$2

