param queueNames     array
param queueService   string
param storageAccount string

resource sa 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageAccount
}

#disable-next-line no-unused-existing-resources
resource qs 'Microsoft.Storage/storageAccounts/queueServices@2022-05-01' existing = {
  name: queueService
}

resource q 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-05-01' = [for (item, index) in queueNames: {
  name: '${sa.name}/default/${item}'
}]

