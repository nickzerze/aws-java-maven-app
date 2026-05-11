pipeline {
    agent any
    environment {
        ANSIBLE_SERVER = "63.179.150.172"
        ANSIBLE_USER = "ubuntu"
    }
    stages {
        stage("copy ansible folder and ec2 access key to ansible-server") {
            steps {
                script {
                    sshagent(['ansible-server-key']) {
                        // Ο ansible server είναι ec2-instance και έχω σαν default user τον ec2-user
                        //  οπότε δεν μπορώ να κάνω copy τα αρχεία στον /root folder απ' ευθείας. 
                        //  Για το λόγο αυτό πάω και τα κάνω μέσω tmp
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
                            sh """
                                scp -o StrictHostKeyChecking=no "$keyfile" ${ANSIBLE_USER}@${ANSIBLE_SERVER}:/tmp/ssh-key.pem
                                ssh -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_SERVER} "sudo mv /tmp/ssh-key.pem /root/ssh-key.pem && sudo chmod 400 /root/ssh-key.pem && sudo chown root:root /root/ssh-key.pem"
                            """
                        }
                    }                               
                }
            }
        }

        stage("execute ansible playbook from the ansible-server") {
            steps {
                script {
                    echo "executing ansible-playbook"
                    
                    def remote = [:]
                    remote.name = "ansible-server"
                    remote.host = ANSIBLE_SERVER
                    remote.allowAnyHosts = true
                    
                    withCredentials([sshUserPrivateKey(credentialsId: 'ansible-server-key', keyFileVariable: 'keyfile', usernameVariable: 'user')]) {
                        remote.identityFile = keyfile
                        remote.user = user

                        //Για να τρέξουν τα παρακάτω πρέπει να εγαταστήσω το Plugin SSH Pipeline Steps
                        sshCommand remote: remote, command: "whoami"
                        sshCommand remote: remote, command: "sudo ls -la /root"
                        // Κάνω το αρχείο prepare-server.sh εκτελέσιμο
                        sshCommand remote: remote, command: "sudo chmod +x /root/prepare-server.sh"
                        // Τρέχω το script που είναι στο /root folder
                        sshCommand remote: remote, command: "sudo bash /root/prepare-server.sh"
                        // Στην ουσία λέμε: Μπες στο /root και μετά τρέξε το command ansible-playbook docker-and-compose.yaml
                        sshCommand remote: remote, command: "sudo bash -c 'cd /root && ansible-playbook docker-and-compose.yaml'"
                    }
                }
            }
        }
    }   
}