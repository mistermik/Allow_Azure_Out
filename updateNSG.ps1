 
function updateNSG($Regions, $VNETName, $SubnetName, $RSGName) {
#$Regions, VNETName, $SubnetName, $RSGName
    # Download and process the XML file with regions
 
    $downloadUri = "https://www.microsoft.com/en-in/download/confirmation.aspx?id=41653"
    try {
        $downloadPage = Invoke-WebRequest -Uri $downloadUri -TimeoutSec 30 -ErrorAction:Stop
        #$downloadPage = Invoke-WebRequest -{Namepii} $downloadUri -TimeoutSec 30 -ErrorAction:Stop
    } catch { 
        Write-Host "Error while loading XML file"
        break 
    }
 
    $xmlFileUri = ($downloadPage.RawContent.Split('"') -like "https://*PublicIps*")[0]
 
    $response = Invoke-WebRequest  $xmlFileUri
 
    # Get list of regions & public IP ranges
 
    [xml]$xmlResponse = [System.Text.Encoding]::UTF8.GetString($response.Content)
 
    $AzureRegions = $xmlResponse.AzurePublicIpAddresses.Region
 
    # Select Azure regions for which to define NSG rules
 
    $ipRange =  ( $AzureRegions | where-object Name -In $regions ).ipRange

############################################################################## 
    #Clone ACTIVE NSG
############################################################################## 
    $VNET=Get-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $RSGName
    $Subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $Subnetname -VirtualNetwork $VNET
    $Subnet.NetworkSecurityGroup.Id
    $ActiveNSG= Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rsgname | where {$_.Id -eq $Subnet.NetworkSecurityGroup.Id}

    #Export Active NSG
    #$ActiveNSG| Get-AzureRmNetworkSecurityRuleConfig | Select * | Export-Csv -NoTypeInformation -Path C:\MF\ActiveNSG01.csv

    #Create New Template NSG
    $NSGnewName="ActiveNSG-"+(get-Date).ToString("MMddyyyy-hh_mm")
    $TemplateNSGRules = $ActiveNSG| Get-AzureRmNetworkSecurityRuleConfig
    $NSGnew = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rsgname -Location $ActiveNSG.Location -Name $NSGnewName

    #Cloning Active Rules into new created NSG
    foreach($rule in $TemplateNSGRules) {
        IF (!($rule.Name -match "Allow_Azure_Out_")) {
        $NSGnew | Add-AzureRmNetworkSecurityRuleConfig -Name $rule.Name -Direction $rule.Direction -Priority $rule.Priority -Access $rule.Access -SourceAddressPrefix $rule.SourceAddressPrefix -SourcePortRange $rule.SourcePortRange -DestinationAddressPrefix $rule.DestinationAddressPrefix -DestinationPortRange $rule.DestinationPortRange -Protocol $rule.Protocol # -Description $rule.Description
        $NSGnew | Set-AzureRmNetworkSecurityGroup
        write-host $rule.Name
        }
    }
############################################################################## 
    #Build NSG rules
###########################################################################
    $rulePriority = 3500

    ForEach ($subnet in $ipRange.Subnet) {
        $ruleName = "Allow_Azure_Out_" + $subnet.Replace("/","-")
        $ruleName
        Get-AzureRmNetworkSecurityGroup -Name $NSGnew.Name -ResourceGroupName $RSGName|
        Add-AzureRmNetworkSecurityRuleConfig -Name $rulename -Protocol * -Direction Outbound -Priority $rulePriority -SourceAddressPrefix "VIRTUALNETWORK" -SourcePortRange '*' -DestinationAddressPrefix "$subnet" -DestinationPortRange '*' -Access Allow |
        Set-AzureRmNetworkSecurityGroup
   
   $rulePriority++
}

############################################################################## 
    # associate the NSG to the subnet. Passive becomes active, and active becomes unassigned
############################################################################## 
    Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $subnetName -NetworkSecurityGroup $NSGnew -AddressPrefix 192.168.1.0/24
    #Update the virtual network
    Set-AzureRmVirtualNetwork -VirtualNetwork $VNET

############################################################################## 
    #Remove previous (Active) NSG
############################################################################## 
$ActiveNsg|Remove-AzureRmNetworkSecurityGroup -Force

}





 
#################################################################################
# start here
#$Regions, VNETName, $SubnetName, $RSGName
 
$regions = @("uswest")     # replace accordingly eg. "uswest","uswest2"
$VNetName = "<VNET name where to apply the NSG>"
$subnetName = "<Subnet name where to apply the NSG>"

 
# periodically, within the period you find suitable, run the command below to update NSG and switch active to passive.

#updateNSG $regions $VnetName $SubnetName $RSGName 
#################################################################################