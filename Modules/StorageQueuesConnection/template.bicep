param name     string
param location string = resourceGroup().location

resource conn 'Microsoft.Web/connections@2016-06-01' = {
  name: name
  location: location
  properties: {
    displayName: name
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azurequeues')
    }
    #disable-next-line BCP089
    parameterValueSet: {
      name: 'managedIdentityAuth'
      values: {}
    }
  }
}

output name string = conn.name
output id   string = conn.id
