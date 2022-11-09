param name     string
param location string = resourceGroup().location
param sku      string = 'Y1'
param tier     string = 'Dynamic'

resource ap 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: name
  location: location
  sku: {
    name: sku
    tier: tier
  }
}

output name string = ap.name
