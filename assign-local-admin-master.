#Powershell to grant local admin to any machine where you're the primary user (in intune). 
#Author: Nick Riley

#########################  Variables #######################
# 
#AD Group for Local Admin
#$ADGroupName = "grpLocalWorkstationAdmins"
#
$ADGroupServiceAccountAdmins = "grpLocalWorkstationAdmin-ServiceAccount"
$ADGroupStandardAccountAdmins = "grpLocalWorkstationAdmin-StandardAccount"
#
$ADComputerGroup = "NL10-Computer-LocalAdmin"
#
$ADLocalAdminGroupOU = "OU=WorkstationAdminGroups,OU=WorkstationAdmin,OU=Global-Services,DC=domain"
$ADServiceAccountOU = "OU=Systems-Administration,OU=Global-Services,DC=domain"
#
#Test with whatif... (we need to connect to AAD first - so check below that connection)
$WhatIfPreference = $false
#
#
$thumb = [your certificate thumb here]
###########################################################

Import-Module AzureAD
Import-Module ActiveDirectory

#Azure AD
#Login to Azure PowerShell with your Service Principal
Connect-AzureAD -TenantId [your tennant id here] -ApplicationId [your app id here] -CertificateThumbprint $thumb -ErrorVariable AADConnectionerror | Out-Null
if ($AADConnectionerror) { echo "AAD Connection Error Found - $AADConnectionError" }

#This is just for testing now we've connected to AAD.
$WhatIfPreference = $true

$ApprovedDevices = @()

#######################################
##########    Functions ###############
#######################################


#Function to Check for a the local admin group, create it, add the user, but also validate no-one else exists in it!
function Set-LocalAdmin($ComputerName, $AdminAccount){
      #Does the AD Group Exist for this machine?
      $thisdevicelocaladmingroup = 'grpLocalAdmin-'+$ComputerName 
      if (-Not (Get-ADGroup -Filter {SamAccountName -eq $thisdevicelocaladmingroup})){ 
            #Group does not already exist
            # Need to create the group for this computer as it doesnt exist - will also generate an alert.
            New-ADGroup -Name $thisdevicelocaladmingroup  -Path $ADLocalAdminGroupOU -GroupScope Global -GroupCategory Security            
            # no need to check if the user is in the group - they arent!
            Add-ADGroupMember  -Identity $thisdevicelocaladmingroup -Members $AdminAccount
            Add-ADGroupMember  -Identity $ADComputerGroup -Members $computername 
            echo "New Group Created, and Added $AdminAccount to $thisdevicelocaladmingroup " 
            }
        else{ 
            #Group does exist...
            $thisdevicelocaladmingroupmembers = Get-ADGroupMember -Identity $thisdevicelocaladmingroup 
            # AD Group already exists - so will check contents...
            if ($thisdevicelocaladmingroupmembers -notcontains $AdminAccount){ 
                # So the Device Local Admin Group does exist - but our Admin is not an admin
                #ADD them here!!
                Add-ADGroupMember -Identity $thisdevicelocaladmingroup -Members $AdminAccount 
                echo "Group Exists so Adding $AdminAccount to $thisdevicelocaladmingroup - was a bit odd as the group existed already" 
                }
            #Now we will loop through the other members of the local admin group for this machine!!  
            foreach ($currentmember in $thisdevicelocaladmingroupmembers) {
                   if ($currentmember.samaccountname -ne $ADusersamaccountname) { 
                     #Wait - who is this in this group? #I'm going to remove them, and trigger an alert!
                     Remove-ADGroupMember -Identity $thisdevicelocaladmingroup -Members $currentmember.samaccountname 
                     echo "Removing $currentmember from $thisdevicelocaladmingroup "
                     }
            }

        }
}



#Function to return a users service account (if it has a matching employee number)
Function Get-ServiceAccount($ADUserSAMAccountName) {
            #First see if we have the employee number;
            $ADUserinfo = Get-ADUser -Identity $ADUserSAMAccountName -Properties EmployeeNumber
            $ADUserEmployeeNumber = $ADUserinfo.EmployeeNumber
            $serviceAccount = Get-ADUser -Filter {EmployeeNumber -eq $ADUserEmployeeNumber} -SearchBase $ADServiceAccountOU
          if ($serviceAccount) { ## service Account does exist...
            $servicesamaccountname = $serviceaccount.samaccountname
            return $servicesamaccountname
            }
          else { 
            ## no service account found 
            Return $false;
            }
    }


#Function to return list of AD Computers for a user - based on AAD registered devices
Function Get-ADComputerInfo($ADUserSAMAccountName) { 
            #Function to use a user SAM name, get their UPN, check AAD for their devices and double check on-prem AD and return values in an array 
            $ADUserinfo = Get-ADUser -Identity $ADUserSAMAccountName
            $ADUserUPN = $ADUserinfo.UserPrincipalName
            $ADComputers = $null
            $AADDevices =  Get-AzureADUserRegisteredDevice -ObjectId $ADUserUPN  | select DisplayName, DirSyncEnabled, DeviceTrustType, ObjectID, DeviceID | Where-Object {$_.DirSyncEnabled -eq "True"}
            foreach ($device in $AADDevices) {
                #Now we'll check on-prem
                $AADcomputername = $device.DisplayName
                $ADComputerObjs = Get-ADComputer -Identity $AADcomputername | Select Name, ObjectGUID, DistinguishedName
                #Quick bit of error checking against the device as we're using displayname not a SAM / UPN... 
                if ($ADComputerObjs.ObjectGUID -ne $device.DeviceID) { echo "Error - Device GUID Not Found in AD" }
                else { 
                    #We've checked the computer - it's the right one;  We'll add the DN to the return array.  
                    $ADComputers + $ADComputerObjs
                 }
            ##echo "end of for each"
             }
             ##echo "Returning whole AADD"
             ##Adding a return in here, seems to create a blank line in the array
             ##return $ADComputers
     }

   
#################################################################################
#################################################################################
############      Main part of the script starts here....   #####################
#################################################################################
#################################################################################

#We'll start with the Service Accounts
#For each user in the AD Group that permits Admin;
$ADUsersinGroup = Get-ADGroupMember -Identity $ADGroupServiceAccountAdmins | Select-Object samAccountName, Name
#
$username = $null
foreach ($username in $ADUsersinGroup) { 
    #get user details
    $ADusersamaccountname = $username.samaccountname
    $AdminAccount = $null
    #See if they have a service account or not...
    if (-Not ($AdminAccount = Get-ServiceAccount $ADusersamaccountname)){ 
        #No service account found - thats akward!
        echo "No Service Account found for $ADusersamaccountname - Please ensure they have a service account with their employee number (or HAF reference) in!" 
        }
    else { #We found their service account, now set as $AdminAccount 
        $thisdevice = $null 
        foreach ($thisdevice in Get-ADComputerInfo $ADuserSamaccountname) { 
            #Add the device, to the list of approved devices
            $ApprovedDevices += $thisdevice.name
            $ComputerName = $thisdevice.name
            Set-LocalAdmin $ComputerName $AdminAccount
            }
         }
    }

#Now we'll run through the standard accounts that need admin.
#For each user in the AD Group that permits Admin;
$ADUsersinGroup = Get-ADGroupMember -Identity $ADGroupStandardAccountAdmins | Select-Object samAccountName, Name
$username = $null
foreach ($username in $ADUsersinGroup) {
   $AdminAccount = $username.samAccountName
   $ADUserSamAccountname = $username.samAccountName
   $thisdevice = $null
   foreach ($thisdevice in Get-ADComputerInfo $ADuserSamaccountname) { 
            #Add the device, to the list of approved devices
            $ApprovedDevices += $thisdevice.name
            $ComputerName = $thisdevice.name
            Set-LocalAdmin $ComputerName $AdminAccount
            }
}

###################
##               ##
##   Clean Up    ##
##               ##
###################

#echo "Approved List: $ApprovedDevices"

#We've cleaned up the groups for approved devices already - so we should be confident that we dont have standard accounts in service account authorised groups.
#Now we'll remove any admin groups we dont need.
#We may want to think about removing the searchbase so it finds everything - depends how we target Group Policy!! 
$ADAdminGroupList = Get-ADGroup -Filter {Name -Like "grpLocalAdmin*"} -SearchBase $ADLocalAdminGroupOU
foreach ($thisADAdminGroup in $ADAdminGroupList) {
        #Get the computer name for the group
        $thisADAdminComputer = $thisADAdminGroup.Name -Replace("grpLocalAdmin-*","")
        if ($ApprovedDevices -notcontains $thisADAdminComputer) { 
            #Oh Dear - unapproved device with an admin group...
            $UnauthorisedGroupMembers = Get-ADGroupMember -Identity $thisADAdminGroup
            $UnauthorisedMembers = $UnauthorisedGroupMembers.Name
            Remove-ADGroup -Identity $thisADAdminGroup 
            echo "Unauthorised Group Found - Removed $thisADAdminGroup - with members: $UnauthorisedMembers"
        }
}

#Now we'll remove any computers from the Computers group too...  (this may not be relevant...  tbc)
$ADGroupComputers = Get-ADGroupMember -Identity $ADComputerGroup
foreach ($thisADGroupComputer in $ADGroupComputers) {
        if ($ApprovedDevices -notcontains $thisADGroupComputer) {
        #Oh dear - unapproved device within the computers group... (depends on GPO deployment if this is relevant?)
        Remove-ADGroupMember -Identity $ADComputerGroup -Members $thisADGroupComputer 
        echo "Unauthorised Computer Found - Removing $thisADGroupComputer from $ADComputerGroup"
        }
}

## So the group policy just adds grpLocalAdmin-%ComputerName% to the workstation.
## When the user / machine is removed - that group is deleted - hence removes access BUT we only delete groups named grpLocalAdmin-* in $ADLocalAdminGroupOU - but you could have a group in another OU.
## 


#We'll disconnect from AzureAD.
Disconnect-AzureAD
