param name        string
param location    string = resourceGroup().location
param connection  string
param storageAcct string

resource la 'Microsoft.Logic/workflows@2019-05-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/schemas/2016-06-01/Microsoft.Logic.json'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                createdTimeUTC: {
                  type: 'string'
                }
                creatorEmail: {
                  type: 'string'
                }
                creatorName: {
                  type: 'string'
                }
                groupId: {
                  type: 'string'
                }
                parameters: {
                  properties: {
                    event: {
                      type: 'string'
                    }
                    force: {
                      type: 'boolean'
                    }
                    product: {
                      type: 'string'
                    }
                    template: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                webDescription: {
                  type: 'string'
                }
                webTitle: {
                  type: 'string'
                }
                webUrl: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        'Initialize_-_Azure_Queue_Message': {
          runAfter: {
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'Azure Queue Message'
                type: 'string'
                value: '{\n    "SiteCollectionUrl" : "@{triggerBody()?[\'webUrl\']}",\n    "Template" : "@{triggerBody()?[\'parameters\']?[\'template\']}",\n    "Force" : "@{toLower(string(triggerBody()?[\'parameters\']?[\'force\']))}"\n}'
              }
            ]
          }
        }
        'Put_a_message_on_a_queue_(V2)': {
          runAfter: {
            'Initialize_-_Azure_Queue_Message': [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: '@variables(\'Azure Queue Message\')'
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azurequeues\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent(\'https://${storageAcct}.queue.core.windows.net\'))}/queues/@{encodeURIComponent(\'ps-queue-items\')}/messages'
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          azurequeues: {
            connectionId: resourceId('Microsoft.Web/connections', connection)
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azurequeues')
          }
        }
      }
    }
  }
}

output principalId string = la.identity.principalId
