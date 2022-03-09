# tacticalrmm-aks setup

## clone this repo

```
git clone https://github.com/redanthrax/tacticalrmm-aks.git

cd tacticalrmm-aks/terraform/
```

## login to azure

```
az login

az account list -o table

az account set --name "Subscription Name"
```

## required customizations

You must decide on a short name for your container registry in azure.
This example uses trmmcontainer but you'll have to use something different.
After picking a name you will need to replace trmmcontainer in all the yaml files and while using this readme with the one you chose.
Ex. az acr login --name trmmcontainer must become the one you choose.

## deploy via terraform

```
cd terraform/

terraform plan
```

Resolve any errors presented

```
terraform apply
```

## build and deploy trmm docker images

```
cd ../../

az acr login --name trmmcontainer

git clone https://github.com/wh1te909/tacticalrmm.git

cd tacticalrmm/docker/

chmod +x image-build.sh

./image-build.sh

docker tag tactical:latest trmmcontainer.azurecr.io/tactical

docker push trmmcontainer.azurecr.io/tactical

docker tag tactical-meshcentral:latest trmmcontainer.azurecr.io/tactical-meshcentral

docker push trmmcontainer.azurecr.io/tactical-meshcentral

docker tag tactical-nginx:latest trmmcontainer.azurecr.io/tactical-nginx

docker push trmmcontainer.azurecr.io/tactical-nginx

docker tag tactical-nats:latest trmmcontainer.azurecr.io/tactical-nats

docker push trmmcontainer.azurecr.io/tactical-nats

docker tag tactical-frontend:latest trmmcontainer.azurecr.io/tactical-frontend

docker push trmmcontainer.azurecr.io/tactical-frontend
```

## login to aks cluster

```
az aks get-credentials --resource-group trmm --name trmm-cluster
```

## setup keyvault secrets auth

```
az aks show -g trmm -n trmm-cluster --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
```

Use output in next command

```
az keyvault set-policy -n trmm-vault --secret-permissions get --spn <identity-client-id>
```

## setup keyvault secrets

Customize the values below to fit your domain and customize the users/passwords for security

```
az keyvault secret set --vault-name trmm-vault -n RmmUrl --value 'rmm.mycompany.com'
az keyvault secret set --vault-name trmm-vault -n ApiUrl --value 'api.mycompany.com'
az keyvault secret set --vault-name trmm-vault -n MeshUrl --value 'mesh.mycompany.com'
az keyvault secret set --vault-name trmm-vault -n PostgresUser --value 'postgresuser'
az keyvault secret set --vault-name trmm-vault -n PostgresPass --value 'mypostgrespass1'
az keyvault secret set --vault-name trmm-vault -n MeshUser --value 'meshuser'
az keyvault secret set --vault-name trmm-vault -n MeshPass --value 'meshpass1'
az keyvault secret set --vault-name trmm-vault -n MongoUser --value 'monguser'
az keyvault secret set --vault-name trmm-vault -n MongoPass --value 'mongopass1'
az keyvault secret set --vault-name trmm-vault -n TrmmUser --value 'tactical'
az keyvault secret set --vault-name trmm-vault -n TrmmPass --value 'tacticalpass1'
```

## setup tactical rmm resources in aks

```
cd aks/

kubectl apply -f namespace.yaml

kubens -> select tacticalrmm
```

## setup fileshare shared storage

```
az storage account keys list --resource-group trmm-resources --account-name trmmstorage --query "[0].value" -o tsv
kubectl create secret generic azure-secret --from-literal=azurestorageaccountname=trmmstorage --from-literal=azurestorageaccountkey='<key from previous command>'
kubectl apply -f storage.yaml
```

## setup secrets

```
az aks show -g trmm -n trmm-cluster --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
```

Replace userAssignedIdentityID with value returned in secrets.yaml

```
az account show --query tenantId -o tsv
```

Replace tenantId with returned value in secrets.yaml

```
kubectl apply -f secrets.yaml
```

## get certificates

install certbot

```
sudo certbot certonly --manual -d '*.example.com' --agree-tos --no-bootstrap --manual-public-ip-logging-ok --preferred-challenges dns
```

Add the txt record to your domain

Continue letsencrypt setup (enter to continue) after a few minutes

Get base64 valus for key and cert

Be sure to replace domain with your actual domain

```
sudo base64 -w 0 /etc/letsencrypt/live/domain.com/fullchain.pem

az keyvault secret set --vault-name trmm-vault -n TrmmCert --value "<value from above command>"
```

```
sudo base64 -w 0 /etc/letsencrypt/live/domain.com/privkey.pem
az keyvault secret set --vault-name trmm-vault -n TrmmKey --value "<value from above command>"
```

## deploy and start the containers

```
kubectl apply -f tactical-postgres.yaml
kubectl apply -f tactical-mongodb.yaml
kubectl apply -f tactical-meshcentral.yaml
kubectl apply -f tactical-init.yaml
kubectl apply -f tactical-nginx.yaml
kubectl apply -f tactical-redis.yaml
kubectl apply -f tactical-celery.yaml
kubectl apply -f tactical-celerybeat.yaml
kubectl apply -f tactical-backend.yaml
kubectl apply -f tactical-frontend.yaml
kubectl apply -f tactical-websockets.yaml
kubectl apply -f tactical-nats.yaml
```

## assign public ip

Get the resource group and the principal id

```
az aks show -g trmm -n trmm-cluster --query identity.principalId -o tsv
az group show --resource-group trmm --query id -o tsv
```

Use the output from the previous commands for the next command

```
az role assignment create --assignee <principal-id> --role "Network Contributor" --scope <resource group id>
az network public-ip show --resource-group trmm --name trmm-pip --query ipAddress -o tsv
```

Change loadBalancerIP to the ip from the above output in loadbalancer.yaml

Change service.beta.kubernetes.io/azure-dns-label-name to something random/custom, if this is taken the loadbalancer won't work

Setup the loadbalancer

```
kubectl apply -f loadbalancer.yaml
```

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