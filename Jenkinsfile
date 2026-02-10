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
        DOCKER_REPO_SERVER = '746688010937.dkr.ecr.eu-central-1.amazonaws.com'
        DOCKER_REPO = "${DOCKER_REPO_SERVER}/java-maven-app"
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
                    env.IMAGE_NAME = "${version}-${BUILD_NUMBER}"
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
                    buildImage("${DOCKER_REPO}:${IMAGE_NAME}")
                    //Επειδή στο jenkins-shared-library repo το docker login το κάνω με τα credentials του docke-hub-repo, για να μην αλλάζω όλο
                    // το shared-library, εδώ στο deploy_on_k8s_using_ECR θα κάνω dockerLogin με withCredentials
                    withCredentials([usernamePassword(credentialsId: 'ecr-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh "echo $PASS | docker login -u $USER --password-stdin ${DOCKER_REPO_SERVER}"
                    }
                    dockerPush("${DOCKER_REPO}:${IMAGE_NAME}")
                }
            }
        }

        stage("deploy") {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                APP_NAME = 'java-maven-app'
            }
            steps {
                script {
                    echo 'Deploying docker image to K8s cluster....'

                    // Το envsubst το θέλω για να φορτώσουν τα variables τα οποία έχω μέσα στο deployment.yaml και service.yaml. 
                    // Θα πρέπει να εγκαταστήσω στο Jenkins το envsubst ΠΡΩΤΑ.  
                    // Το envsubst < kubernetes/deployment.yaml παράγει το αρχείο γεμισμένο με τα σωστά variables και μετά περνιέται 
                    // σαν όρισμα στο τέλος την εντολής kubectl apply -f -
                    sh 'envsubst < Kubernetes/deployment.yaml | kubectl apply -f -'
                    sh 'envsubst < Kubernetes/service.yaml | kubectl apply -f -'
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
						
                        sh "git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/nickzerze/aws-java-maven-app.git"

                        sh 'git add .'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:deploy_on_k8s'
                    }
                }
            }
        }              
    }
} 
