#!/bin/bash

while getopts c:v:k:s: flag
do
    case "${flag}" in
        c) container=${OPTARG};;
        v) version=${OPTARG};;
        k) keyvault=${OPTARG};;
        s) storageaccount=${OPTARG};;
    esac
done

if test -z "$container" || test -z "$version" || test -z "$keyvault" || test -z "$storageaccount"
then
    echo "setup.sh expect -c for container and -v for image version -k for keyvault -s for storage account: Eg ./setup.sh -c mycontainer -v 0.12.0 -k mykeyvault -s mystorage"
else
    echo "Container: $container.azurecr.io";
    echo "Version: $version";
    echo "Keyvault: $keyvault";

    az acr login --name $container

    docker tag tactical:latest $container.azurecr.io/tactical:$version

    docker push $container.azurecr.io/tactical:$version

    docker tag tactical-meshcentral:latest $container.azurecr.io/tactical-meshcentral:$version

    docker push $container.azurecr.io/tactical-meshcentral:$version

    docker tag tactical-nginx:latest $container.azurecr.io/tactical-nginx:$version

    docker push $container.azurecr.io/tactical-nginx:$version

    docker tag tactical-nats:latest $container.azurecr.io/tactical-nats:$version

    docker push $container.azurecr.io/tactical-nats:$version

    docker tag tactical-frontend:latest $container.azurecr.io/tactical-frontend:$version

    docker push $container.azurecr.io/tactical-frontend:$version

    echo "Time to setup $keyvault secrets"

    read -p "Enter the Base URL (eg mycompany.com): " baseurl

    az keyvault secret set --vault-name $keyvault -n RmmUrl --value "rmm.$baseurl" > /dev/null

    az keyvault secret set --vault-name $keyvault -n ApiUrl --value "api.$baseurl" > /dev/null

    az keyvault secret set --vault-name $keyvault -n MeshUrl --value "mesh.$baseurl" > /dev/null

    read -p "Postgres User (eg postgresuser): " postgresuser

    az keyvault secret set --vault-name $keyvault -n PostgresUser --value $postgresuser > /dev/null

    read -p "Posgres Password (eg postgresspass1): " postgrespass

    az keyvault secret set --vault-name $keyvault -n PostgresPass --value $postgrespass > /dev/null

    read -p "Mesh User (eg meshuser): " meshuser

    az keyvault secret set --vault-name $keyvault -n MeshUser --value $meshuser > /dev/null

    read -p "Mesh Password (eg meshpass1): " meshpass

    az keyvault secret set --vault-name $keyvault -n MeshPass --value $meshpass > /dev/null

    read -p "Mongo User (eg mongouser): " mongouser

    az keyvault secret set --vault-name $keyvault -n MongoUser --value $mongouser > /dev/null

    read -p "Mongo Password (eg mongopass1): " mongopass

    az keyvault secret set --vault-name $keyvault -n MongoPass --value $mongopass > /dev/null

    read -p "Tactical User (eg tacticaluser): " tacticaluser

    az keyvault secret set --vault-name $keyvault -n TrmmUser --value $tacticaluser > /dev/null

    read -p "Tactical Password (eg tacticalpass1): " tacticalpass

    az keyvault secret set --vault-name $keyvault -n TrmmPass --value $tacticalpass > /dev/null

    az aks get-credentials --resource-group trmm --name trmm-cluster

    az aks update -g trmm -n trmm-cluster --enable-secret-rotation

    identity=$(az aks show -g trmm -n trmm-cluster --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)

    echo "Found and using identity $identity";

    az keyvault set-policy -n $keyvault --secret-permissions get --spn $identity > /dev/null

    echo "Setting up role identity"

    clusteridentity=$(az aks show -g trmm -n trmm-cluster --query identity.principalId -o tsv)

    resourceGroupId=$(az group show --resource-group trmm --query id -o tsv)

    az role assignment create --assignee $clusteridentity --role "Network Contributor" --scope $resourceGroupId > /dev/null

    echo "Setting up certificate with LetsEncrypt Certbot"

    sudo certbot certonly --manual -d "*.$baseurl" --agree-tos --no-bootstrap --manual-public-ip-logging-ok --preferred-challenges dns

    fullchain=$(sudo base64 -w 0 /etc/letsencrypt/live/$baseurl/fullchain.pem)

    az keyvault secret set --vault-name $keyvault -n TrmmCert --value $fullchain > /dev/null

    privkey=$(sudo base64 -w 0 /etc/letsencrypt/live/$baseurl/privkey.pem)

    az keyvault secret set --vault-name $keyvault -n TrmmKey --value $privkey > /dev/null

    pip=$(az network public-ip show --resource-group trmm --name trmm-pip --query ipAddress -o tsv)
    uai=$(az aks show -g trmm -n trmm-cluster --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
    tid=$(az account show --query tenantId -o tsv)
    spostgres=$(az disk show --name postgres --resource-group trmm-resources --query id -o tsv)
    smongodb=$(az disk show --name mongodb --resource-group trmm-resources --query id -o tsv)
    smesh=$(az disk show --name meshdata --resource-group trmm-resources --query id -o tsv)
    sredis=$(az disk show --name redis --resource-group trmm-resources --query id -o tsv)
    storagekey=$(az storage account keys list --resource-group trmm-resources --account-name $storageaccount --query '[0].value' -o tsv)

    echo "Configuration parameters for helm values.yaml"
    echo "Loadbalancer IP: $pip"
    echo "UserAssignedIdentity: $uai"
    echo "TenantID: $tid"
    echo "Storage Account: $storageaccount"
    echo "Storage Key: $storagekey"
    echo "Storage Postgres: $spostgres"
    echo "Storage Mongodb: $smongodb"
    echo "Storage Mesh: $smesh"
    echo "Storage Redis: $sredis"
    echo "Container Regitry: $container"
    echo "Keyvault: $keyvault"
fi