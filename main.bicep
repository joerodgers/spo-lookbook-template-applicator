param location string = resourceGroup().location
param suffix   string = toLower(uniqueString(resourceGroup().id))

// storage account
module storage 'Modules/StorageAccount/template.bicep' = {
  name: 'storage-account'
  params: {
    name: 'st${suffix}'
    location: location
    networkAcls: {bypass: 'AzureServices', defaultAction: 'Allow'}
  }
}

// storage queue service
module queueservices 'Modules/StorageQueueService/template.bicep' = {
  name: 'storage-queue-services'
  params: {
    storageAccount: storage.outputs.name
  }
}

// storage queues
module azurequeues 'Modules/StorageQueues/template.bicep' = {
  name: 'storge-queues'
  params: {
    queueNames: ['ps-queue-items', 'ps-queue-items-poison']
    queueService: queueservices.outputs.name
    storageAccount: storage.outputs.name
  }
}

// queue connection
module queueconn 'Modules/StorageQueuesConnection/template.bicep' = {
  name: 'storage-queues-connection'
  params: {
    name: 'api-queues-${suffix}'
    location: location
  }
}

// log workspace
module workspace 'Modules/OperationalInsights/template.bicep' = {
  name: 'log-workspace'
  params: {
    name: 'log-${suffix}'
    location: location
  }
}

// app insights
module appinsights 'Modules/AppInsights/template.bicep' = {
  name: 'application-insights'
  params: {
    name: 'appi-${suffix}'
    location: location
    workspace: workspace.outputs.name
  }
}

// app service plan
module appsvc 'Modules/AppService/template.bicep' = {
  name: 'app-service'
  params: {
    name: 'plan-${suffix}'
    location: location
  }
}

// function app
module functionapp 'Modules/FunctionApp/template.bicep' = {
  name: 'function-app'
  params: {
    appService: appsvc.outputs.name
    name: 'func-${suffix}'
    location: location    
    storage: storage.outputs.name
    insights: appinsights.outputs.name
  }
}

// logic app
module logicapp 'Modules/LogicApp/template.bicep' = {
  name: 'logic-app'
  params: {
    connection: queueconn.outputs.name
    name: 'logic-${suffix}'
    location: location
    storageAcct: storage.outputs.name
  }
}

// role assignments
module roleassignments 'Modules/RoleAssignments/template.bicep' = {
  name: 'roleassignments'
  params: {
    roleAssignments: [
      {
        principalId: functionapp.outputs.principalId
        roleDefinitionId: '8a0f0c08-91a1-4084-bc3d-661d67233fed' // Storage Queue Data Message Processor - https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
        principalType: 'ServicePrincipal'
      }
      {
        principalId: logicapp.outputs.principalId
        roleDefinitionId: 'c6a89b2d-59bc-44d0-9896-0f6e12d7b80a' // Storage Queue Data Message Sender - https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
        principalType: 'ServicePrincipal'
      }
      //{
      //  principalId: logicapp.outputs.principalId
      //  roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader - https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
      //  principalType: 'ServicePrincipal'
      //}
    ]
  }
}

output functionApp            string = functionapp.outputs.name
output functionAppPrincipalId string = functionapp.outputs.principalId
