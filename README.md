# Azure Multi-VNet Infrastructure with Terraform and Jenkins CI/CD

This project automates the deployment, connectivity testing, and cleanup of a network architecture in Azure using Terraform for Infrastructure as Code (IaC) and Jenkins for automation.

## Architecture Overview
The infrastructure consists of the following components:
* **Resource Group**: A centralized container named `azure-project-rg` located in the West Europe region.
* **Virtual Networks (VNets)**: Two distinct networks, `vnet-a` (10.1.0.0/16) and `vnet-b` (10.2.0.0/16).
* **VNet Peering**: Bi-directional peering established between both VNets to enable private cross-network communication.
* **Compute**: A total of 4 Windows Server 2019 Virtual Machines, deployed as 2 nodes per VNet (`vm-a-0`, `vm-a-1`, `vm-b-0`, `vm-b-1`).
* **Managed Disks**: Custom-named OS disks (`vnet-a-disk-0/1` and `vnet-b-disk-0/1`) ensuring a clean and professional resource naming convention.
* **Security**: A Network Security Group (NSG) named `project-nsg` with a specific rule (`allow-icmp-all`) to permit ICMP (Ping) traffic between the internal address spaces.

## Automation Pipeline
The lifecycle is managed by a single Jenkins pipeline named **Azure-Create-Test-Destroy-Infrastructure**:

1. **Infrastructure Deployment**: Automatically provisions the entire environment using `terraform init` and `terraform apply`.
2. **Connectivity Validation**: 
    * Retrieves the target VM's private IP dynamically from Terraform outputs.
    * Uses Azure CLI `run-command` to execute a ping test from `vm-a-0` to the destination VM in VNet-B.
3. **Automated Cleanup**: The pipeline ensures cost efficiency by executing `terraform destroy` in the `post` execution stage.

## Project Assets & Validation
All deployment evidence and validation results are organized within the `images/` directory:
* **`Deloyed_resources.jpeg`**: Verification of all 4 VM instances, symmetric managed disks, and network components.
* **`Pipeline_Stages.png`**: Visual representation of the Jenkins Stage View, showing the successful sequence from initialization to cleanup.
* **`Connectivity_Test.jpeg`**: Log output showing 0% packet loss during cross-VNet communication.
* **`Pipeline_Azure-Create-Test-Destroy-Infrastructure.png`**: Overall pipeline status and execution summary.

## Prerequisites
* Active Azure Subscription with a Service Principal.
* Jenkins environment with **Terraform** and **Azure CLI** installed independently.
* Credentials configured in Jenkins: `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`.

## Execution Workflow
1. Clone the repository and ensure the `images/` folder is correctly populated.
2. Push the code to your GitHub repository.
3. Configure a Jenkins Pipeline job pointing to the project's `Jenkinsfile`.
4. Trigger the build to deploy, verify, and decommission the infrastructure automatically.