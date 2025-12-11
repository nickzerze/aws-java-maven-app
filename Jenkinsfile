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
    stages {
        stage("Increment Version") {
             steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_NAME = "malware4/${version}-${BUILD_NUMBER}"
                }
            }           
        }

        stage("build app") {
            steps {
                script {
                    echo "Building the application jar..."
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
                        sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null server-cmds.sh ec2-user@18.197.254.226:/home/ec2-user"
                        sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null docker-compose.yaml ec2-user@18.197.254.226:/home/ec2-user"
                        sh "ssh -o StrictHostKeyChecking=no ec2-user@18.197.254.226 ${shellCmd}"
                    }
                }
            }
        } 

        stage('commit version update') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-groovy', passwordVariable: 'GIT_PASS', usernameVariable: 'GIT_USER')]) {
                        // git config here for the first time run
                        //SOS δες ότι για credentials χρησιμοποιώ το github-groovy το οποίο στο password ΔΕΝ έχει το πραγματικό password
                        //αλλά το token που έχω φτιάξει.
                        sh 'git config --global user.email "jenkins@example.com"'
                        sh 'git config --global user.name "jenkins"'
						sh 'git status'
						sh 'git branch'
						sh 'git config --list'
						
                        sh "git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/nickzerze/java-maven-app.git"

                        sh 'git add .'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:jenkins-jobs'
                    }
                }
            }
        }              
    }
} 
