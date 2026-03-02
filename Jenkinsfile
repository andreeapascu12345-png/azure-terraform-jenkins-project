pipeline {
    agent any

    tools {
        // Must match the name defined in Jenkins Global Tool Configuration
        terraform 'terraform'
    }

    environment {
        // Azure service principal credentials from Jenkins Credentials Store
        ARM_CLIENT_ID       = credentials('AZURE_CLIENT_ID')
        ARM_CLIENT_SECRET   = credentials('AZURE_CLIENT_SECRET')
        ARM_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
        ARM_TENANT_ID       = credentials('AZURE_TENANT_ID')
    }

    stages {
        stage('Checkout') {
            steps {
                // Pulls the latest code from the GitHub repository
                checkout scm
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    echo "Initializing and deploying Azure infrastructure..."
                    // Using single quotes to prevent Groovy from interpreting shell commands
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Connectivity Test') {
            steps {
                script {
                    echo "Starting Connectivity Test between Virtual Machines..."
                    
                    // 1. Retrieve the target VM Private IP from Terraform output
                    env.TARGET_IP = sh(script: 'terraform output -raw target_vm_ip', returnStdout: true).trim()
                    echo "Target IP for testing: ${env.TARGET_IP}"

                    // 2. Perform Connectivity Test using Azure CLI Run-Command
                    // Using triple single quotes (''') to handle shell variables ($) securely
                    sh '''
                        az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
                        
                        echo "Step A: Enabling ICMP (Ping) in Windows Firewall on Destination VM (vm-b-0)..."
                        az vm run-command invoke --command-id RunPowerShellScript \
                           --name vm-b-0 --resource-group azure-project-rg \
                           --scripts 'netsh advfirewall firewall add rule name="Allow ICMPv4" protocol=icmpv4:8,any dir=in action=allow'
                        
                        echo "Step B: Executing Ping from Source VM (vm-a-0) to Destination IP..."
                        az vm run-command invoke --command-id RunPowerShellScript \
                           --name vm-a-0 --resource-group azure-project-rg \
                           --scripts "ping -n 4 $TARGET_IP"
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                // This block runs regardless of success or failure to avoid unnecessary costs
                echo "Post-Execution: Cleaning up resources..."
                sh 'terraform destroy -auto-approve'
                cleanWs() // Deletes the workspace directory to save disk space
            }
        }
    }
}