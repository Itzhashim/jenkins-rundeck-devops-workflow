#!/usr/bin/env bash
# ==============================================================================
# Azure Infrastructure Deployment Script
# Deploys 2 Cost-Optimized VMs on Azure (Student Subscription Friendly)
# VM 1: vm-jenkins (CI Server)
# VM 2: vm-rundeck (Operations & Deployment Server)
# ==============================================================================

set -eo pipefail

RESOURCE_GROUP="rg-devops-college-project"
LOCATION="eastus"
VNET_NAME="vnet-devops"
SUBNET_NAME="subnet-devops"
VM_SIZE="Standard_B2s" # 2 vCPU, 4GB RAM (Cost-effective for student credits)
ADMIN_USERNAME="azureuser"
SSH_KEY_PATH="${HOME}/.ssh/id_rsa.pub"

echo "======================================================================"
echo "          AZURE INFRASTRUCTURE PROVISIONING AUTOMATION                "
echo "======================================================================"
echo "Resource Group  : ${RESOURCE_GROUP}"
echo "Location        : ${LOCATION}"
echo "VM Size         : ${VM_SIZE} (Burst-capable, student budget friendly)"
echo "Admin User      : ${ADMIN_USERNAME}"
echo ""

# 1. Create Resource Group
echo "[1/7] Creating Resource Group..."
az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}" --output table

# 2. Create Virtual Network & Subnet
echo "[2/7] Creating Virtual Network and Subnet..."
az network vnet create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${VNET_NAME}" \
    --address-prefix 10.0.0.0/16 \
    --subnet-name "${SUBNET_NAME}" \
    --subnet-prefix 10.0.1.0/24 \
    --output table

# 3. Create Network Security Groups
echo "[3/7] Creating Network Security Groups..."
# NSG for Jenkins VM (Allow SSH:22, Jenkins:8080)
az network nsg create --resource-group "${RESOURCE_GROUP}" --name "nsg-jenkins" --output table
az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "nsg-jenkins" \
    --name "Allow-SSH" --priority 1000 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 22 --output table
az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "nsg-jenkins" \
    --name "Allow-Jenkins-Web" --priority 1010 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 8080 --output table

# NSG for Rundeck VM (Allow SSH:22, Rundeck:4440, App:8080)
az network nsg create --resource-group "${RESOURCE_GROUP}" --name "nsg-rundeck" --output table
az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "nsg-rundeck" \
    --name "Allow-SSH" --priority 1000 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 22 --output table
az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "nsg-rundeck" \
    --name "Allow-Rundeck-Web" --priority 1010 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 4440 --output table
az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "nsg-rundeck" \
    --name "Allow-DevopsApp-Port" --priority 1020 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 8080 --output table

# 4. Create Public IPs
echo "[4/7] Allocating Public IPs..."
az network public-ip create --resource-group "${RESOURCE_GROUP}" --name "pip-jenkins" --allocation-method Static --sku Standard --output table
az network public-ip create --resource-group "${RESOURCE_GROUP}" --name "pip-rundeck" --allocation-method Static --sku Standard --output table

# 5. Create Network Interfaces
echo "[5/7] Creating NICs..."
az network nic create --resource-group "${RESOURCE_GROUP}" --name "nic-jenkins" \
    --vnet-name "${VNET_NAME}" --subnet "${SUBNET_NAME}" --network-security-group "nsg-jenkins" \
    --public-ip-address "pip-jenkins" --output table

az network nic create --resource-group "${RESOURCE_GROUP}" --name "nic-rundeck" \
    --vnet-name "${VNET_NAME}" --subnet "${SUBNET_NAME}" --network-security-group "nsg-rundeck" \
    --public-ip-address "pip-rundeck" --output table

# 6. Deploy Virtual Machines (Ubuntu 22.04 LTS)
echo "[6/7] Provisioning Virtual Machines (Ubuntu 22.04 LTS)..."
az vm create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "vm-jenkins" \
    --nics "nic-jenkins" \
    --image "Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest" \
    --size "${VM_SIZE}" \
    --admin-username "${ADMIN_USERNAME}" \
    --generate-ssh-keys \
    --output table

az vm create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "vm-rundeck" \
    --nics "nic-rundeck" \
    --image "Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest" \
    --size "${VM_SIZE}" \
    --admin-username "${ADMIN_USERNAME}" \
    --generate-ssh-keys \
    --output table

# 7. Configure Cost Control: Auto-Shutdown at 19:00 UTC
echo "[7/7] Enabling Cost-Control Auto-Shutdown (Crucial for Azure Student Credit protection)..."
az vm auto-shutdown -g "${RESOURCE_GROUP}" -n "vm-jenkins" --time 1900 --output table
az vm auto-shutdown -g "${RESOURCE_GROUP}" -n "vm-rundeck" --time 1900 --output table

echo ""
echo "======================================================================"
echo "          PROVISIONING COMPLETED SUCCESSFULLY!                        "
echo "======================================================================"
JENKINS_IP=$(az network public-ip show -g "${RESOURCE_GROUP}" -n "pip-jenkins" --query ipAddress -o tsv)
RUNDECK_IP=$(az network public-ip show -g "${RESOURCE_GROUP}" -n "pip-rundeck" --query ipAddress -o tsv)
echo "Jenkins Server Public IP : ${JENKINS_IP}"
echo "Rundeck Server Public IP : ${RUNDECK_IP}"
echo ""
echo "Next Steps:"
echo "1. Run azure/setup-jenkins-vm.sh on ${JENKINS_IP}"
echo "2. Run azure/setup-rundeck-vm.sh on ${RUNDECK_IP}"
echo "3. Remember to stop VMs when not in use: az vm deallocate -g ${RESOURCE_GROUP} --name <vm-name>"
echo "======================================================================"
