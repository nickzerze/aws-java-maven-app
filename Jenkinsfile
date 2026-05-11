pipeline {
    agent any
    environment {
        ANSIBLE_SERVER = "3.74.44.62"
        ANSIBLE_USER = "ubuntu"
    }
    stages {
        stage("copy ansible folder and ec2 access key to ansible-server") {
            steps {
                script {
                    sshagent(['ansible-server-key']) {
                        echo "Creating temp directory on ansible server"
                        sh """
                            ssh -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_SERVER} "mkdir -p /tmp/ansible"
                        """

                        echo "Copying ansible folder to ansible server"
                        sh """
                            scp -o StrictHostKeyChecking=no -r ansible/* ${ANSIBLE_USER}@${ANSIBLE_SERVER}:/tmp/ansible/
                        """

                        echo "Moving ansible files to /root"
                        sh """
                            ssh -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_SERVER} "sudo cp -r /tmp/ansible/* /root/"
                        """
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