# tacticalrmm-aks

az login

az account list -o table

az account set --name "Subscription Name"

cd terraform/

terraform plan

terraform apply

cd ..

az aks get-credentials --resource-group trmm --name trmm-cluster

cd aks/

kubectl apply -f namespace.yaml

az disk list --resource-group trmm | grep id

replace storage.yaml disk id with value

kubectl apply -f storage.yaml