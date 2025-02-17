pipeline {
    agent any

    environment {
        // Specify the private key for SSH access to the EC2 instance
        AWS_SSH_KEY = credentials('ec2-ssh-key')  // Use Jenkins credentials for secure handling of keys
        EC2_PUBLIC_IP = 'your-ec2-public-ip'      // Replace with your EC2 instance's public IP
        EC2_USER = 'ec2-user'                      // User to SSH as (e.g., ec2-user for Amazon Linux)
        SCRIPT_PATH = '/path/to/your-script.sh'    // Path to your script on the EC2 instance
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
