# tacticalrmm-aks

git clone https://github.com/redanthrax/tacticalrmm-aks.git

cd tacticalrmm-aks/terraform/

az login

az account list -o table

az account set --name "Subscription Name"

cd terraform/

terraform plan

terraform apply

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

az aks get-credentials --resource-group trmm --name trmm-cluster

cd aks/

kubectl apply -f namespace.yaml

az disk list --resource-group trmm | grep id

replace storage.yaml disk id with value

kubectl apply -f storage.yaml