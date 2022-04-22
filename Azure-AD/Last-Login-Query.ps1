#AAD Login Times for Everyone (in a specific AD Group)
#I did start with this guide;  
#https://thesysadminchannel.com/get-azure-ad-last-login-date-and-sign-in-activity/
#
#Install-Module AzureADPreview
#Import-Module AzureADPreview
#You'll need to connect to Azure-AD - I tent to just run this interactively, then run the script. 
#Connect-AzureAD

$ADGroupName = "UK-Sales-Department" 
$ExportPath = "C:\Users\Nick\$ADGroupName-Export.csv"

$UsersToCheck = (Get-ADGroupMember -Identity $ADGroupName | Where objectClass -EQ "user" | Get-ADUser | select UserPrincipalName).UserPrincipalName
Write-Host -f Green "AD Group Query - Complete - Total Found: "$UsersToCheck.count 

$count = 0
$thiscounter = 0
$result = @()

foreach ($User in $UsersToCheck) {
    $UserLower = $User.ToLower()
     Write-Host -f Cyan "Query about to run for number: $count ($thiscounter of the batch) ($User) "
    $result += Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$UserLower'" -Top 1 | Select UserPrincipalName,IPAddress,CreatedDateTime
 
    $count++ 
    $thiscounter ++
    if ($thiscounter -gt "5"){ 
            Write-Host -f Red "Sleeping following batch of $thiscounter"
            $thiscounter = 0 
            Start-Sleep -s 10
            }
}

Write-Host -f Green "Total of $count Records Checked - Writing CSV to $ExportPath " 
echo $result | Export-CSV -Path $ExportPath






                                                              
