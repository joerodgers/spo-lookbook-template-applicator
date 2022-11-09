param location string = resourceGroup().location
param suffix   string = toLower(uniqueString(resourceGroup().id))

// storage account post deployment to set network acls
module storage_acls 'Modules/StorageAccount/template.bicep' = {
  name: 'storage-account-acls'
  params: {
    name: 'st${suffix}'
    location: location
    networkAcls: {bypass: 'AzureServices', defaultAction: 'Deny'}
  }
}

