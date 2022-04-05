#!/bin/bash

while getopts c:v:k:s: flag
do
    case "${flag}" in
        c) container=${OPTARG};;
        v) version=${OPTARG};;
    esac
done

if test -z "$container" || test -z "$version"
then
    echo "update.sh expect -c for container and -v for image version: Eg ./update.sh -c mycontainer -v 0.12.0"
else
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
fi