# TacticalRMM-AKS setup

## Requirements

Installed Linux Distro (Arch, Debian, Ubuntu, etc) - Not tested in Windows WSL
Git
Azure CLI
Terraform CLI
Docker
Helm

## Clone this repo

```
git clone https://github.com/redanthrax/tacticalrmm-aks.git

cd tacticalrmm-aks/terraform/
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
cd terraform/

terraform plan
```

Resolve any errors presented

```
terraform apply
```

## Additional Setup

The images are tagged in the instructions with the latest version per this writing. Check the Tactical RMM repo and tag appropriately.

```

git clone https://github.com/wh1te909/tacticalrmm.git

cd tacticalrmm/docker/

chmod +x image-build.sh

./image-build.sh

cd ../../

chmod +x setup.sh

./setup.sh -c trmmcontainer -v 0.12.0 -k keyvaultname -s storageaccount (refer to the container registry you named in terraform.tfvars)
```

## Setup with helm

```
helm package tacticalrmm-helm

helm install tacticalrmm ./tacticalrmm-0.1.0.tgz
```

## DNS Setup

Setup api.mycompany.com, mesh.mycompany.com, and rmm.mycompany.com to point at your loadbalancer ip address.

## Get mesh download

You need to shell into the tactical-backend pod that is running.

Install k9s

When running k9s navigate to the pod that begins with tactical-backend, press the s key to open a shell

Run the following command

```
python manage.py get_mesh_exe_url
```

Copy and paste the url into your browser and download the 64 bit windows exe.

Login to your instance at rmm.mycompany.com with the default user created before.

Create your first client and upload the exe.

Hit me up at the tactical rmm discord for questions.

## Disaster Recovery

Create an Azure Backup Vault

Create a Backup Policy in the vault

Add meshdata, mongodb, postgres, and redis to the backup

Create an Azure Backup Recovery Vault

Select the file share and use the Backup under Operations

## Updating

TBD