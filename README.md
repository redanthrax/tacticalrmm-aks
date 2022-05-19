# TacticalRMM-AKS setup

## Requirements

Installed Linux Distro (Arch, Debian, Ubuntu, etc) - Not tested in Windows WSL
- Git
- Azure CLI
- Terraform CLI
- Docker
- Helm

## Clone this repo

```
git clone https://github.com/redanthrax/tacticalrmm-aks.git
```

## Login to Azure Subscription

```
az login
az account list -o table
az account set --name "Subscription Name"
```

## Required Customizations

Updates to terraform.tfvars file.

Customize the following:
- container_registry_name
- vaultname
- storageaccount

## Deploy Infrastructure via Terraform

```
cd tacticalrmm-aks/terraform/
terraform plan
```

Resolve any errors presented

```
terraform apply
```

It should show the additions and ask for confirmation.
This will take a few minutes to apply.
If you receive errors during the process try running terraform apply again. Sometimes it will try to create the disks before the 'resources' resource group is created.

## Setup the images and cluster

The images are tagged in the instructions with the latest version per this writing. Check the Tactical RMM repo and tag appropriately via tacticalrmm-helm/values.yaml.

```
cd ../../
git clone https://github.com/wh1te909/tacticalrmm.git
cd tacticalrmm/docker/
chmod +x image-build.sh
./image-build.sh
cd ../../tacticalrmm-aks/
chmod +x setup.sh
```

setup.sh expects a number of flags
- -c for the container name
- -v for the version
- -k for the key vault name
- -s for the storage account name

Use the container name, key vault name, and storage account name you specified in tacticalrmm-aks/terraform/terraform.tfvars.

```
./setup.sh -c trmmcontainer -v 0.12.0 -k keyvaultname -s storageaccount
```

The setup script will have you setup your URL and additional parameters for usernames and passwords required.

After the script completes rename tacticalrmm-aks/tacticalrmm-helm/values.example.yaml to values.yaml.

Replace the variables with the ones provided by the setup.sh script.

## Setup with helm

```
helm package tacticalrmm-helm
helm install tacticalrmm ./tacticalrmm-0.1.0.tgz
```

## DNS Setup

Setup api.mycompany.com, mesh.mycompany.com, and rmm.mycompany.com to point at your loadbalancer ip address.

## Disaster Recovery

Create an Azure Backup Vault

Create a Backup Policy in the vault

Add meshdata, mongodb, postgres, and redis to the backup

Create an Azure Backup Recovery Vault

Select the file share and use the Backup under Operations

## Updating

Navigate to the repo cloned previously and pull the latest changes from the master branch.

```
az login
az account list -o table
az account set --name "Subscription Name"
cd tacticalrmm/
git pull
cd docker/
./image-build.sh
cd ../../tacticalrmm-aks/
./update.sh -c trmmcontainer -v (new version here based on the latest release like 0.12.2)
```

Update the image tag in the helm values.yaml file and the appVersion in the helm Chart.yaml file to match the latest version.
```
helm package tacticalrmm-helm
helm upgrade tacticalrmm ./tacticalrmm-0.1.0.tgz
```

## Updating Certificates
Run the following script and follow the prompts.

```
./renewcerts.sh -k trmmkeyvault
```

Build the package with helm again and deploy in order to update the cert store.

```
helm package tacticalrmm-helm
helm upgrade tacticalrmm ./tacticalrmm-0.1.0.tgz
```