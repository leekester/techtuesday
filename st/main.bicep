targetScope = 'resourceGroup'

param name string
param skuName string
param kind string
param supportsHttpsTrafficOnly bool
param accessTier string
param allowBlobPublicAccess bool
param allowSharedKeyAccess bool
param minimumTlsVersion string
param allowedIps array

resource storage1 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: name
  location: resourceGroup().location
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    minimumTlsVersion: minimumTlsVersion
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: [ for allowedIp in allowedIps: {
        action: 'Allow'
        value: allowedIp
      }]
    }
  }
}