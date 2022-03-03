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

## deploy via terraform

```
cd terraform/

terraform plan

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

az aks get-credentials --resource-group trmm --name trmm-cluster

## enable azure secrets addons

```
az aks enable-addons --addons azure-keyvault-secrets-provider --name trmm-cluster --resource-group trmm
```
## setup keyvault secrets

```
az aks show -g trmm -n trmm-cluster --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
```

Use output in next command

```
az keyvault set-policy -n trmm-vault --secret-permissions get --spn <identity-client-id>
```

## setup keyvault secrets

```
az keyvault secret set --vault-name trmm-vault -n PostgresUser --value 'postgresuser'
az keyvault secret set --vault-name trmm-vault -n PostgresPass --value 'mypostgrespass1'
az keyvault secret set --vault-name trmm-vault -n MeshUser --value 'meshuser'
az keyvault secret set --vault-name trmm-vault -n MeshPass --value 'meshpass1'
az keyvault secret set --vault-name trmm-vault -n MongoUser --value 'monguser'
az keyvault secret set --vault-name trmm-vault -n MongoPass --value 'mongopass1'
az keyvault secret set --vault-name trmm-vault -n TrmmUser --value 'tatical'
az keyvault secret set --vault-name trmm-vault -n TrmmPass --value 'tacticalpass1'
```

## setup tactical rmm resources in aks

```
cd aks/

kubectl apply -f namespace.yaml

az disk list --resource-group trmm-resources | grep id
```

replace storage.yaml disk id with value

```
kubectl apply -f storage.yaml

kubectl apply -f sharedvolume.yaml
```

## setup secrets

```
az aks show -g trmm -n trmm-cluster --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
```

Replace userAssignedIdentityID with value returned

```
az account show | grep tenantId
```

Replace tenantId with returned value

```
kubectl apply -f secrets.yaml
```

kubectl apply -f tactical-init.yaml

kubectl apply -f tactical-postgres.yaml

kubectl apply -f tactical-meshcentral.com