pipeline {
    agent any
    environment {
        ANSIBLE_SERVER = "3.74.44.62"
    }
    stages {
        stage("copy ansible folder and ec2 access key to ansible-server") {
            steps {
                script {
                    sshagent(['ansible-server-key']) {
                        echo "copying ansible folder to ansible server"
                        // ${ANSIBLE_SERVER}:/root without root will give jenkins@${ANSIBLE_SERVER}:/root
                        sh "scp -o StrictHostKeyChecking=no ansible/* ubuntu@${ANSIBLE_SERVER}:/root"    

                        echo "copying ssh keys for ec2 instances"
                        withCredentials([sshUserPrivateKey(credentialsId: 'ec2-server-key', keyFileVariable: 'keyfile', usernameVariable: 'user')]) {
                            sh 'scp -o StrictHostKeyChecking=no $keyfile root@$ANSIBLE_SERVER:/root/ssh-key.pem'
                        }
                    }                               
                }
            }
        }
    }   
}