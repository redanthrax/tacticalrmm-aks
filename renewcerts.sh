#!/bin/bash

while getopts c:v:k:s: flag
do
    case "${flag}" in
        k) keyvault=${OPTARG};;
    esac
done

if test -z "$keyvault"
then
    echo "renewcerts.sh expects -k for keyvault: Eg ./renewcerts.sh -k mykeyvault"
else
    echo "Keyvault: $keyvault";
    read -p "Enter the Base URL (eg mycompany.com): " baseurl
    sudo certbot certonly --manual -d "*.$baseurl" --agree-tos --no-bootstrap --manual-public-ip-logging-ok --preferred-challenges dns
    fullchain=$(sudo base64 -w 0 /etc/letsencrypt/live/$baseurl/fullchain.pem)
    az keyvault secret set --vault-name $keyvault -n TrmmCert --value $fullchain > /dev/null
    privkey=$(sudo base64 -w 0 /etc/letsencrypt/live/$baseurl/privkey.pem)
    az keyvault secret set --vault-name $keyvault -n TrmmKey --value $privkey > /dev/null
    kubectl delete secret trmmcert --namespace tacticalrmm
    kubectl delete secret trmmkey --namespace tacticalrmm
    echo "Keyvault certificates updated."
    echo "Run the deployment via helm to update the certs in the volume store."
fi