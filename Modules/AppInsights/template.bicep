param name     string
param location string = resourceGroup().location
param workspace string 

resource ws 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspace
}

resource ai 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: ws.id    
  }
}

output name string = ai.name
