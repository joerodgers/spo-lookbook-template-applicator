param storageAccount string

resource st 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageAccount
}

resource qs 'Microsoft.Storage/storageAccounts/queueServices@2022-05-01' = {
  name: 'default'
  parent: st
}

output name string = st.name
