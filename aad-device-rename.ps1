#Intune Device Rename Script
#Script checks devices in an AAD Group for a naming format, then checks their serial number (from Intune) and renames based on a variable in the CSV.
#
#
#Variables:-
#Location of the CSV
$ZebraFilePath = "$env:HOMEPATH\Documents\Zebra-HHT.csv"

#AzureAD Group with the HHTs in
$GroupID = "xxx-xxx-xxx-xxx-xxx-xxx-xxx-xxx"

#Set $AskToConfirm to $false to fully automate a run.
$AskToConfirm = $true

#You'll only need this once on your machine;
#Install-Module -Name Microsoft.Graph.Intune
#Install-Module -Name AzureAD

#Now we'll connect to AzureAD & Intune (Graph)! (You'll want to comment these out if you keep re-running)
#Connect-AzureAD
#Connect-MSGraph

function Set-NewName($StoreNumber,$DeviceObjectID,$OriginalDeviceName){
   #This function will get the first lowest available number of the HHT based on existing names;
   $NewNamePrefix="Zebra-HHT-$StoreNumber"

   #Lets get everything else with the prefix and then we'll work out the lowest; 
   $ExistingDevices = Get-AzureADDevice -SearchString $NewNamePrefix | Select DisplayName

   $RenamedOK = $false 
   $startnum = 0  #Start at zero because the first thing we do is add one.

   do {
     $startnum++
     #convert to 2 digit number (good for upto 99 devices as we start at 01).      
     $thisnum = "{0:D2}" -f $startnum
     $NewNameFull = "$NewNamePrefix-$thisnum"
     #unless we can see it already in the list, we'll rename - that way we start at the lowest.
     if ($ExistingDevices.DisplayName -notcontains $NewNameFull) { 
        
        if ($AskToConfirm -eq $True){  $InputAnswer = Read-Host -Prompt "Would you like to rename $OriginalDeviceName to $NewNameFull (type Y to rename)?" }
            
        if ($AskToConfirm -eq $false -or ($AskToConfirm -eq $true -and $InputAnswer -eq "Y")) {
            Set-AzureADDevice -ObjectId $DeviceObjectID -DisplayName $NewNameFull
            Write-Host -BackgroundColor Green "Renamed $OriginalDeviceName to $NewNameFull (ObjectID: $DeviceObjectID)"
            }

            $RenamedOK = $true
       } 
     else { 
        #Write-Host -BackgroundColor Yellow "Found $NewNameFull in AAD - will try the next number - $startnum so far" 
        $RenamedOK = $false
          #Just catch and stop infinite loops - but 99 is our limit anyway.
          if ($startnum -eq "99"){ 
            Write-Host -BackgroundColor Red "Got to 99 trying to rename $NewNameFull ($DeviceObjectID) - will quit)"
            $RenamedOK = $true
          } 
        #still in the Do loop and not closing it, so it'll cary on.
        }
   } 
   while ($RenamedOK -eq $false)

}


#Now the function is defined, we'll see what we need to rename:- 
$RenameNeeded = Get-AzureADGroupMember -ObjectId ec3be152-3af0-4f71-8c10-dc5f25babc4d | Where-Object DisplayName -notlike "Zebra*"

if ($RenameNeeded.Count -gt 0){ Write-Host -ForegroundColor Green "Found "($RenameNeeded).Count " Devices to Update" }
else { Write-Host -ForegroundColor Red "Nothing Found to Update in AzureAD" exit; }

#We are also going to read in the CSV as we now know we'll need to use it; 
$CSVimport = Import-CSV $ZebraFilePath -Header null1, null2, serialnumber, devicetype, address, null3, fullstorename, storenumber, null4, macaddress, null9
#
$counter = 0
foreach ($device in $RenameNeeded){
  $counter ++
  $DeviceName = $device.displayname
  $DeviceObjectID = $device.ObjectId
  $DeviceID = $device.DeviceId
 
  #Write-Host -ForegroundColor Cyan "Asking Intune for ManagedDevice $DeviceID"

  #Need to dive into Intune to get the SerialNumber (I cant find it in AzureAD)
  $IntuneError = $false
    try { $IntuneData = Get-IntuneManagedDevice -managedDeviceId $DeviceID -ErrorAction SilentlyContinue }
    catch { 
        Write-Host -BackgroundColor Red "$DeviceName Not Found in Intune (ObjID: $DeviceObjectID) - Please Enroll"
        $IntuneError = $true
    }
  
  if ($IntuneError -eq $false){ 
  
    $SerialNumber = $IntuneData.serialNumber
    #Write-Host -ForegroundColor Green $counter " $SerialNumber currently called $DeviceName"
    #Let's find it in the CSV
    $FoundItem = $CSVimport.Where({ ($_).serialnumber -eq $SerialNumber}) 
    if ($FoundItem) { 
      $StoreNumber = $FoundItem.storenumber 
      #Write-Host -BackgroundColor Cyan "$SerialNumber Found in Store $Storenumber - for $DeviceObjectID"
      Set-NewName $Storenumber $DeviceObjectID $DeviceName
     }
     else { Write-Host -BackgroundColor Red "$SerialNumber Not Found in CSV - but it is called $DeviceName in AzureAD" }
   }
  }
