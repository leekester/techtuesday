param function string

@allowed([
  'dev'
  'sbx'
  'nft'
  'qa'
  'tst'
  'uat'
  'prd'
])
param environment string

@minLength(2)
@maxLength(2)
param instance string

param name string = '${function}${environment}${instance}'

param vNet object
param location string = resourceGroup().location

@allowed([
  'Standard_B2s'
 ])
param vmSize string = 'Standard_B2s'

param imageReference object = {
  'publisher': 'MicrosoftWindowsServer'
  'offer': 'WindowsServer'
  'sku': '2022-datacenter-g2'
  'version': 'latest'
}

param osDisk object = {
  'osType': 'Windows'
  'createOption': 'FromImage'
  'caching': 'ReadWrite'
  'writeAcceleratorEnabled': false
  'storageAccountType': 'StandardSSD_LRS'
  'diskSizeGB': 127
}

param dataDisks array = []

param osProfile object = {
  'adminUserName': 'megaadmin'
  'provisionVMAgent': true
  'enableAutomaticUpdates': true
  'patchMode': 'AutomaticByOS'
  'assessmentMode': 'ImageDefault'
  'enableHotpatching': false
  'allowExtensionOperations': true
}

@secure()
param adminPassword string

param bootDiagnosticsEnabled bool = true

param subnet string = 'snet-server2022'

// Get vNet ID to reference during machine deployment
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vNet.name
  scope: resourceGroup(vNet.resourceGroup)
}

// ** TODO **
// We may need to cater for multiple NICs

resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-${name}'
  location: 'uksouth'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${virtualNetwork.id}/subnets/${subnet}'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

output nicId string = nic.id

resource name_resource 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: toLower(name)
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: imageReference.publisher
        offer: imageReference.offer
        sku: imageReference.sku
        version: imageReference.version
      }
      osDisk: {
        osType: osDisk.osType
        name: '${name}_osdisk'
        createOption: osDisk.createOption
        caching: osDisk.caching
        writeAcceleratorEnabled: osDisk.writeAcceleratorEnabled
        managedDisk: {
          storageAccountType: osDisk.storageAccountType
        }
        diskSizeGB: osDisk.diskSizeGb
      }


// Disk creation and attachment reference here...
// https://dev.to/omiossec/azure-how-to-build-a-reusable-multi-data-disks-vm-arm-template-2ghn

      dataDisks: [ for dataDisk in dataDisks: {
          lun: dataDisk.lun
          name: '${name}_${dataDisk.diskName}'
          createOption: dataDisk.createOption
//          caching: dataDisk.caching
//          writeAcceleratorEnabled: dataDisk.writeAcceleratorEnabled
          managedDisk: {
            storageAccountType: dataDisk.diskSku
//            id: '${name}_${dataDisk.diskName}'
          }
          diskSizeGB: dataDisk.diskSizeGB
      }]
    }
    osProfile: {
      computerName: name
      adminUsername: osProfile.adminUserName
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: osProfile.provisionVmAgent
        enableAutomaticUpdates: osProfile.enableAutomaticUpdates
        patchSettings: {
          patchMode: any(osProfile.patchMode)
          assessmentMode: any(osProfile.assessmentMode)
          enableHotpatching: osProfile.enableHotpatching
        }
      }
      secrets: []
      allowExtensionOperations: osProfile.allowExtensionOperations

      //      ** TODO **
      //      Check the below...
      //      This isn't enabled in my personal subscription, but may be relevant in a corporate context
      //      requireGuestProvisionSignal: osProfile.requireGuestProvisionSignal

    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: bootDiagnosticsEnabled
      }
    }
  }
}