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
                    env.IMAGE_NAME = "malware4/java-maven-app:${version}-${BUILD_NUMBER}"
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
                    dockerLogin() // Αυτό μπορεί να γίνει ο Jenkins χρησιμοποιεί τα credentials που έχω φτιάξει στο Jenkins
                    dockerPush(env.IMAGE_NAME)
                }
            }
        }

        stage("Provision server") {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                TF_VAR_env_prefix = 'test'
            }
            steps {
                script {
                    dir('terraform') {
                        sh "terraform init"
                        sh "terraform apply --auto-approve"
                        EC2_PUBLIC_IP = sh(
                            script: "terraform output ec2_public_ip",
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }

        stage("deploying") {
            environment {
                DOCKER_CREDS = credentials('docker-hub-repo') // τα DOCKER_CREDS_USR και DOCKER_CREDS_PWD φτιάχνονται αυτόματα
            }
            steps {
                script {
                    // Προσθέτω ένα sleep time ώστε να έχει χρόνο το ec2-instance που φτιάχτηκε στο προηγούμενο stage να κάνει initialize
                    echo 'waiting for EC2 server to initialize'
                    sleep (time: 90, unit: "SECONDS") // Μπορώ να βάλω ένα if...else που θα τρέχει το sleep μόνο όταν ο server δεν είναι up, πχ την πρώτη φορά μόνο, και όχι πάντα με αποτέλεσμα να μου καθυστερεί το pipeline
                    echo "${EC2_PUBLIC_IP}"
            
                    echo 'Deploying docker image to EC2 instance....'
                    //def dockerComposeCmd = "docker compose -f docker-compose.yaml up --detach"

                    def shellCmd = "bash ./server-cmds.sh ${env.IMAGE_NAME} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"
                    // def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"  -> μπορώ να βάλω αυτό στις 3 εντολές μέσα στο sshagent

                    sshagent(['myapp-server-ssh-key']) {
                        //Πρώτα κάνω copy το server-cmds.sh στο EC2 instance 
                        sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null server-cmds.sh ec2-user@${EC2_PUBLIC_IP}:/home/ec2-user"

                        //Μετά κάνω copy το docker-compose.yaml στο EC2 instance
                        sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null docker-compose.yaml ec2-user@${EC2_PUBLIC_IP}:/home/ec2-user"

                        //Με ssh τρέχω το server-cmds.sh μέσω της εντολής shellcmd που παίρνει και σαν παράμετρο το IMAGE_NAME για να περαστεί μετά στο docker-compose.yaml
                        sh "ssh -o StrictHostKeyChecking=no ec2-user@${EC2_PUBLIC_IP} ${shellCmd}"
                    }
                }
            }
        }        

        stage('commit version  update') {
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
						
                        sh "git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/nickzerze/aws-java-maven-app.git"

                        sh 'git add .'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:jenkins-with-terraform'
                    }
                }
            }
        }              
    }
} 
