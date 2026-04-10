###Setup PC
#   #[As Admin]
#   Set-ExecutionPolicy -ExecutionPolicy Unrestricted
#   #
##
#Update-Module PnP.Powershell
#Install-Module -Name PnP.Powershell -force
#

#[2026 update] - PNP needs an app registration for you to connect.
#Run this to create the app - and then get the AppID (it will tell you in the console)
#Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP.PowerShell" -Tenant vfxplc.onmicrosoft.com
Connect-PnPOnline -Url https://xxxx.sharepoint.com/sites/[name] -tenant xxx.onmicrosoft.com -ClientId 1234-5678-9101112-12

#Set the folder we're going to delete stuff from:-
#$FolderServerRelativeURL = "Shared Documents/[folderpath]/Folder/no-slash-on/end"
$FolderServerRelativeURL = "Shared Documents"
#Set the number of versions to keep.
$VersionsToKeep = 250
#Delete Previous Versions where the total size is over xxxMb (1024 - means only files over 1Gb will be targetted)
$DeleteOverMb = 1024
#

Function Cleanup-Versions($folder)
{ 
    #Iterate through each file
    ForEach ($File in $folder)
    {
        #Get File Versions
        $Versions = Get-PnPProperty -ClientObject $File -Property Versions        
        $TotalVersions = $Versions.Count
        $VersionsToDelete = $TotalVersions - $VersionsToKeep
        #$Size = Get-PnPProperty -ClientObject $File -Property Size
        $rawsize = $Versions | Measure-Object -Property Size -Sum | Select-Object -expand Sum
        $Totalsize = [Math]::Round(($rawsize/1048576),2)
        #Write-Host -f Green "`t `t"$File.Name" has $TotalVersions - so I will keep $VersionsToKeep - with $VersionsToDelete to delete - its $size MB and $singversionrawsize MB big" 
        if (($TotalVersions -gt $VersionsToKeep) -and ($Totalsize -gt $DeleteOverMb))
        {
              Write-Host -f Green "`t `tCleaning Up File:"$file.Name" (using $Totalsize Mb with $TotalVersions Versions)"
              $batch = 150
              $batchcount = 0
              ##dont just itterate through a number...
              $ToDelete = $Versions | Select-Object -First $VersionsToDelete
                foreach ($Version in $ToDelete) {
                Write-Host "Deleting version $($Version.VersionLabel) of $($File.Name) - size $([Math]::Round(($Version.Size/1048576),2)) Mb"

                $Version.DeleteObject()
                $batchcount++ 
                if ($batchcount -eq $batch) { 
                  Write-Host -f DarkGreen "Batch of $batch Deletions - Executing ";
                  Invoke-PnPQuery;  
                  $batchcount = 0
                }
            }
              Write-Host -f DarkGreen "Running final query - no batch"
              Invoke-PnPQuery
              #Write-Host -f Red "Done"
            
        }
        else { #Write-host -f Yellow "`tSkipping:"$File.Name"  - $TotalVersions Versions and $Totalsize Mb "  
        }

    }

}

$SPFolder = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderServerRelativeURL -Recursive -ItemType File
Cleanup-Versions -Folder $SPFolder

#Completely re-written, but with some help from here: https://www.sharepointdiary.com/2018/05/sharepoint-online-delete-version-history-using-pnp-powershell.html#ixzz7HwEq9cp3
