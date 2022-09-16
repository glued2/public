#General Azure VMSS Powershell Commands.

#Connect-AzAccount
#Set-AzContext

$resourcegroup = "xxx-xxx"
$vmssname = "vmss-name"

#Get Balance:-  (True - means strict, no scaling in Zone Failure), False means best efforts). 
Get-AzVMss -VMScaleSetName vmss-pr-sapcom-sfap-uks-01 | select ZoneBalance

#Query the VMSS, get the zone each VM is in, and display that together with the status of the VM and the name.
Get-AzVmssVM -ResourceGroupName $resourcegroup -VMScaleSetName $vmssname -InstanceView | Select {$_.InstanceView.Statuses.DisplayStatus},Zones,Name
