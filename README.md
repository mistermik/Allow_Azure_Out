Azure Network Security Group
Restrict Azure VM to only allow traffic to specific Azure public IP addresses
=============
Be very careful on “Deny All” outbound Internet traffic as you may prevent
Azure VM Agent and access to blobs and other functionalities not to work
properly. 
This script Imports an update set of Azure Public IP downloading and processing the "Microsoft Azure Datacenter IP Ranges" xml document,
It creates a new NSG with a new updated set of SecurityRule then, It finally associates this last NSG with the Subnet and delete the previous.

Example of NSG Rules created, processing the  https://www.microsoft.com/en-in/download/confirmation.aspx?id=41653:

  "Name": "Allow_Azure_Out_191.238.70.0-23",
                           "Protocol": "*",
                           "SourcePortRange": "*",
                           "DestinationPortRange": "*",
                           "SourceAddressPrefix": "VIRTUALNETWORK",
                           "DestinationAddressPrefix": "191.238.70.0/23",
                           "Access": "Allow",
                           "Priority": 3588,
                           "Direction": "Outbound",
                           "ProvisioningState": "Succeeded"
                         } 


Usage
-----
```ruby
Function: updateNSG
Parameters:
$regions = @("uswest")
$VnetName="Vnet"
$SubnetName = "Default"
$RSGName = "NSGPassiveActive-RSG" 

=> updateNSG $regions $VnetName $SubnetName $RSGName
 ```

Contributing
------------
Special Thanks to Sérgio Velho 

![Screenshot](NSG.png)

