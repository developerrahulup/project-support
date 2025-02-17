pipeline {
    agent any

    environment {
         // AWS credentials stored in Jenkins
        AWS_ACCESS_KEY = credentials('aws-access-key-id')    // AWS Access Key
        AWS_SECRET_KEY = credentials('aws-secret-access-key') // AWS Secret Key
        EC2_SSH_KEY_PATH = credentials('ec2-pem-key') // The path or content of the PEM key
        EC2_PUBLIC_IP = '10.56.71.118'     // Public IP of EC2 instance
        SCRIPT_PATH = './gpg-checksum-check.sh'    // Path to your script on the EC2 instance
    }

    stages {
        stage('Setup') {
            steps {
                script {
                    // This can be used to install dependencies if needed
                    echo "Setting up the environment..."
                }
            }
        }

        stage('Execute Script on EC2') {
            steps {
                sshagent (credentials: [AWS_SSH_KEY]) {
                    sh """
                        echo 'Running script on EC2 instance...'
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_PUBLIC_IP} 'bash -s' < ${SCRIPT_PATH}
                    """
                }
            }
        }

        stage('Post Execution') {
            steps {
                echo "Script execution completed."
            }
        }
    }

    post {
        success {
            echo 'Build and script execution successful!'
        }
        failure {
            echo 'Build failed, check the logs!'
        }
    }
}
