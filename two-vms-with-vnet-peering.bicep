@description('Location of the VNET1')
@allowed([
  'eastus2'
  'uk'
  'uae'
  'japaneast'
  'japanwest'
])
param vnet1_location string = 'japaneast'

@description('Location of the VNET2')
@allowed([
  'eastus2'
  'uk'
  'uae'
  'japaneast'
  'japanwest'
])
param vnet2_location string = 'japanwest'

@description('Name for vNet 1')
param vnet1_Name string = 'vNet1'

@description('Name for vNet 2')
param vnet2_Name string = 'vNet2'

var vnet1Config = {
  addressSpacePrefix: '10.1.0.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '10.1.0.0/24'
}
var vnet2Config = {
  addressSpacePrefix: '10.2.0.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '10.2.0.0/24'
}

/*vm1 の設定用変数*/
@description('The name of you Virtual Machine.')
param vmName_vm1 string = 'vm1'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix_vm1 string = toLower('${vmName_vm1}-${uniqueString(resourceGroup().id)}')

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '12.04.5-LTS'
  '14.04.5-LTS'
  '16_04_0-lts-gen2'
  '18_04-LTS-gen2'
])
param ubuntuOSVersion string = '18_04-LTS-gen2'

@description('The size of the VM')
param vmSize string = 'Standard_B2s'

@description('Name of the Network Security Group')
param networkSecurityGroupName1 string = 'SecGroupNet1'

var publicIPAddressName_vm1 = '${vmName_vm1}PublicIP'
var networkInterfaceName_vm1 = '${vmName_vm1}NetInt'
var osDiskType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

/*vm2 の設定用変数*/
@description('The name of you Virtual Machine.')
param vmName_vm2 string = 'vm2'

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix_vm2 string = toLower('${vmName_vm2}-${uniqueString(resourceGroup().id)}')


@description('Name of the Network Security Group')
param networkSecurityGroupName2 string = 'SecGroupNet2'

var publicIPAddressName_vm2 = '${vmName_vm2}PublicIP'
var networkInterfaceName_vm2 = '${vmName_vm2}NetInt'

/*仮想ネットワークの構成*/
resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet1
  name: vnet1Config.subnetName
  properties: {
    addressPrefix: vnet1Config.addressSpacePrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource vnet1 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnet1_Name
  location: vnet1_location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet1Config.addressSpacePrefix
      ]
    }
  }
}

resource VnetPeering1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnet1
  name: '${vnet1_Name}-${vnet2_Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet2.id
    }
  }
}

resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet2
  name: vnet2Config.subnetName
  properties: {
    addressPrefix: vnet2Config.addressSpacePrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource vnet2 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnet2_Name
  location: vnet2_location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet2Config.addressSpacePrefix
      ]
    }
  }
}

resource vnetPeering2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnet2
  name: '${vnet2_Name}-${vnet1_Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet1.id
    }
  }
  dependsOn: [
    VnetPeering1
  ]
}

/*VM1 の構成*/
resource nic1 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: networkInterfaceName_vm1
  location: vnet1_location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet1.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP1.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg1.id
    }
  }
}

resource nsg1 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: networkSecurityGroupName1
  location: vnet1_location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource publicIP1 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIPAddressName_vm1
  location: vnet1_location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix_vm1
    }
    idleTimeoutInMinutes: 4
  }
}

resource vm1 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName_vm1
  location: vnet1_location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1.id
        }
      ]
    }
    osProfile: {
      computerName: vmName_vm1
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
  }
  dependsOn:[
    VnetPeering1
    vnetPeering2
  ]
}

/*vm2 の構成*/
resource nic2 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: networkInterfaceName_vm2
  location: vnet2_location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet2.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP2.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg2.id
    }
  }
}

resource nsg2 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: networkSecurityGroupName2
  location: vnet2_location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource publicIP2 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIPAddressName_vm2
  location: vnet2_location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix_vm2
    }
    idleTimeoutInMinutes: 4
  }
}

resource vm2 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName_vm2
  location: vnet2_location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic2.id
        }
      ]
    }
    osProfile: {
      computerName: vmName_vm2
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
  }
  dependsOn:[
    VnetPeering1
    vnetPeering2
  ]
}

