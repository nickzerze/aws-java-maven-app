#!/usr/bin.env groovy

pipeline {   
    agent any
    stages {
        stage("test") {
            steps {
                script {
                    echo "Testing the application....."

                }
            }
        }
        stage("build") {
            steps {
                script {
                    echo "Building the application......"
                }
            }
        }

        stage("deploy") {
            steps {
                script {
                    def dockerCmd = 'docker run -p 8080:8080 -d malware4/java-maven-app:1.1.11-27'
                    sshagent(['ec2-instance-aws-java-maven-app']) {
                        sh "ssh -o StrictHostKeyChecking=no ec2-user@63.178.246.127 ${dockerCmd}"
                    }
                }
            }
        }               
    }
} 
