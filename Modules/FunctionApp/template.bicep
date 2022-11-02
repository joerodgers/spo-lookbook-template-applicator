param name       string 
param location   string = resourceGroup().location
param appService string
param storage    string
param insights   string

resource as 'Microsoft.Web/serverfarms@2021-01-01' existing = {
  name: appService
}

resource st 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storage
}

resource ai 'Microsoft.Insights/components@2020-02-02' existing = {
  name: insights
}

resource fa 'Microsoft.Web/sites@2020-12-01' = {
  name: name
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: as.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${st.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${st.listKeys().keys[0].value}'
        }
        {
          name: 'AzureWebJobsStorage__queueServiceUri'
          value: 'https://${st.name}.queue.${environment().suffixes.storage}'
        }

        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${st.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${st.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: ai.properties.InstrumentationKey
        }
      ]
      powerShellVersion: '7.0' // need to stay at version 7.0 until this issue is fixed: https://github.com/pnp/powershell/issues/2136
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
    }
  }
}

output name        string = fa.name
output principalId string = fa.identity.principalId
