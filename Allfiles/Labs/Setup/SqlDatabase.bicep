@secure()
param sqlAdminPw string
param location string = resourceGroup().location
param sqlAdminUsername string = 'dp300admin'
param uniqueSuffix string
param adminIpAddress string

var sqlServerName = 'dp300-lab-${uniqueSuffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: 'dp300-lab-${uniqueSuffix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
    ]
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPw
    version: '12.0'
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: 'AdventureWorksLT'
  parent: sqlServer
  location: location
  properties: {
    createMode: 'Default'
    sampleName: 'AdventureWorksLT'
    requestedBackupStorageRedundancy: 'Local' // Remove if needed
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: 'dp300-${uniqueSuffix}-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: 'sqlPrivateLink'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: ['sqlServer']
        }
      }
    ]
  }
}

resource firewallRules 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: 'AllowAllAzureServices'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource firewallRuleCurrentIP 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: 'AllowCurrentIP'
  parent: sqlServer
  properties: {
    startIpAddress: adminIpAddress
    endIpAddress: adminIpAddress
  }
}

output sqlServerName string = sqlServer.name
output sqlAdminUsername string = sqlAdminUsername
output sqlDatabaseName string = sqlDB.name
output vnetName string = vnet.name
output privateEndpointName string = privateEndpoint.name
