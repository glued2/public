##########################################################################################################################################################
## Powershell commands for organisations where they want to prevent external (federated) chat, but allow it for just a few select users  
##
##########################################################################################################################################################

Connect-MicrosoftTeams

## Check Existing Settings  (expect to see AllowFederatedUsers as False is its blocked globally)
 Get-CsTenantFederationConfiguration
 ## now check the policies  (Global will be everyone unless otherwise specified)
 Get-CsExternalAccessPolicy
 ## Check the user - and see what policies they have assigned - you're looking for an ExternalAccessPolicy - if it's black, they'll get the Global
 Get-CsUserPolicyAssignment -Identity nick@z1ylt.onmicrosoft.com

 #Create a new policy and assign it.  (You could user FederationanPICDefault) 
   New-CsExternalAccessPolicy -Identity "CustomAllowPolicy" -EnableFederationAccess $true
   # Assign it
   New-CsBatchPolicyAssignmentOperation -PolicyType ExternalAccessPolicy -PolicyName "CustomAllowPolicy" -Identity nick@z1ylt.onmicrosoft.com
   ## Can check if you want to
   # Get-CsUserPolicyAssignment -Identity nick@z1ylt.onmicrosoft.com

#This is the poorly documented bit that's a bit confusing.
#Change change the Global user setting, then change the tenent bit:-
  Set-CsExternalAccessPolicy -Identity Global -EnabledFederationAccess $false   
  #Now change the tenant level setting. 
  Set-CsTenantFederationConfiguration -AllowFederatedUsers $true

  
