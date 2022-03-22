resource_group_name		= "trmm"
location				= "westus2"
dns_prefix				= "trmm"
tags					= { terraform = "yes", resource = "AKS" }
address_space			= ["10.1.0.0/16"]
subnet					= ["10.1.0.0/24"]
publicip_sku			= "Standard"
kubernetes_version		= "1.22.6"
machinesize				= "Standard_D2s_v3"
networkplugin			= "azure"
loadbalancer_sku		= "Standard"
networkpolicy			= "azure"
#Customize
container_registry_name = "testtrmmregistry"
vaultname               = "testtrmmvault"
storageaccount          = "testtrmmstorage"