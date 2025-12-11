#!/usr/bin.env groovy

library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
    [$class: 'GitSCMSource',
    remote: 'https://github.com/nickzerze/jenkins-shared-library.git',
    credentialsId: 'github-credentials'
    ]
)

pipeline {   
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        IMAGE_NAME = 'malware4/java-maven-app:aws-2.0'
    }
    stages {
        stage("build app") {
            steps {
                script {
                    echo "Building the application jar...."
                    buildJar()
                }
            }
        }
        stage("build image") {
            steps {
                script {
                    echo "Building the docker image..."
                    buildImage(env.IMAGE_NAME)
                    dockerLogin()
                    dockerPush(env.IMAGE_NAME)
                }
            }
        }

        stage("deploy") {
            steps {
                script {
                    echo 'Deploying docker image to EC2 instance...'
                    //def dockerComposeCmd = "docker compose -f docker-compose.yaml up --detach"

                    def shellCmd = "bash ./server-cmds.sh ${env.IMAGE_NAME}"

                    sshagent(['ec2-instance-aws-java-maven-app']) {
                        sh "scp server-cmds.sh ec2-user@63.180.240.90:/home/ec2-user"
                        sh "scp docker-compose.yaml ec2-user@63.180.240.90:/home/ec2-user"
                        sh "ssh -o StrictHostKeyChecking=no ec2-user@63.180.240.90 ${shellCmd}"
                    }
                }
            }
        }               
    }
} 
