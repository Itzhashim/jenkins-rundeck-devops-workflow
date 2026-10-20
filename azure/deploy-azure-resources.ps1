<#
.SYNOPSIS
    Azure Infrastructure Deployment Script (PowerShell)
    Deploys 2 Cost-Optimized VMs on Azure (Student Subscription Friendly)
#>

$ResourceGroup = "rg-devops-college-project"
$Location = "eastus"
$VNetName = "vnet-devops"
$SubnetName = "subnet-devops"
$VmSize = "Standard_B2s"
$AdminUsername = "azureuser"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "       AZURE INFRASTRUCTURE PROVISIONING AUTOMATION (POWERSHELL)      " -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. Create Resource Group
Write-Host "`n[1/7] Creating Resource Group: $ResourceGroup in $Location..." -ForegroundColor Green
az group create --name $ResourceGroup --location $Location --output table

# 2. Virtual Network & Subnet
Write-Host "`n[2/7] Creating Virtual Network and Subnet..." -ForegroundColor Green
az network vnet create `
    --resource-group $ResourceGroup `
    --name $VNetName `
    --address-prefix 10.0.0.0/16 `
    --subnet-name $SubnetName `
    --subnet-prefix 10.0.1.0/24 `
    --output table

# 3. Network Security Groups
Write-Host "`n[3/7] Configuring Network Security Groups..." -ForegroundColor Green
az network nsg create --resource-group $ResourceGroup --name "nsg-jenkins" --output table
az network nsg rule create --resource-group $ResourceGroup --nsg-name "nsg-jenkins" `
    --name "Allow-SSH" --priority 1000 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 22 --output table
az network nsg rule create --resource-group $ResourceGroup --nsg-name "nsg-jenkins" `
    --name "Allow-Jenkins-Web" --priority 1010 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 8080 --output table

az network nsg create --resource-group $ResourceGroup --name "nsg-rundeck" --output table
az network nsg rule create --resource-group $ResourceGroup --nsg-name "nsg-rundeck" `
    --name "Allow-SSH" --priority 1000 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 22 --output table
az network nsg rule create --resource-group $ResourceGroup --nsg-name "nsg-rundeck" `
    --name "Allow-Rundeck-Web" --priority 1010 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 4440 --output table
az network nsg rule create --resource-group $ResourceGroup --nsg-name "nsg-rundeck" `
    --name "Allow-DevopsApp-Port" --priority 1020 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 8080 --output table

# 4. Public IPs
Write-Host "`n[4/7] Allocating Standard Public IPs..." -ForegroundColor Green
az network public-ip create --resource-group $ResourceGroup --name "pip-jenkins" --allocation-method Static --sku Standard --output table
az network public-ip create --resource-group $ResourceGroup --name "pip-rundeck" --allocation-method Static --sku Standard --output table

# 5. Network Interfaces
Write-Host "`n[5/7] Creating Network Interfaces..." -ForegroundColor Green
az network nic create --resource-group $ResourceGroup --name "nic-jenkins" `
    --vnet-name $VNetName --subnet $SubnetName --network-security-group "nsg-jenkins" `
    --public-ip-address "pip-jenkins" --output table

az network nic create --resource-group $ResourceGroup --name "nic-rundeck" `
    --vnet-name $VNetName --subnet $SubnetName --network-security-group "nsg-rundeck" `
    --public-ip-address "pip-rundeck" --output table

# 6. Virtual Machines (Ubuntu 22.04 LTS)
Write-Host "`n[6/7] Creating Ubuntu 22.04 LTS VMs..." -ForegroundColor Green
az vm create `
    --resource-group $ResourceGroup `
    --name "vm-jenkins" `
    --nics "nic-jenkins" `
    --image "Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest" `
    --size $VmSize `
    --admin-username $AdminUsername `
    --generate-ssh-keys `
    --output table

az vm create `
    --resource-group $ResourceGroup `
    --name "vm-rundeck" `
    --nics "nic-rundeck" `
    --image "Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest" `
    --size $VmSize `
    --admin-username $AdminUsername `
    --generate-ssh-keys `
    --output table

# 7. Cost Control Auto-Shutdown
Write-Host "`n[7/7] Configuring Daily Auto-Shutdown (19:00 UTC) to Save Credits..." -ForegroundColor Green
az vm auto-shutdown -g $ResourceGroup -n "vm-jenkins" --time 1900 --output table
az vm auto-shutdown -g $ResourceGroup -n "vm-rundeck" --time 1900 --output table

# Fetch Public IPs
$JenkinsIP = az network public-ip show -g $ResourceGroup -n "pip-jenkins" --query ipAddress -o tsv
$RundeckIP = az network public-ip show -g $ResourceGroup -n "pip-rundeck" --query ipAddress -o tsv

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "Azure Provisioning Complete!" -ForegroundColor Green
Write-Host "Jenkins Server IP: http://${JenkinsIP}:8080" -ForegroundColor Yellow
Write-Host "Rundeck Server IP: http://${RundeckIP}:4440" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan
