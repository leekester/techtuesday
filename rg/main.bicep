targetScope = 'subscription'

param name string

@allowed([
  'uksouth'
  'ukwest'
])
param location string = 'uksouth'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: name
  location: location
}