###Setup PC
#   #[As Admin]
#   Set-ExecutionPolicy -ExecutionPolicy Unrestricted
#   #
##
#Update-Module PnP.Powershell
#Install-Module -Name PnP.Powershell -force
#

#First Connect - this can be done manually...
#Connect-PnPOnline -Url https://[sitename].sharepoint.com/sites/[site] -UseWebLogin

#Set the folder we're going to delete stuff from:-
$FolderServerRelativeURL = "Shared Documents/[folderpath]/Folder/no-slash-on/end"
#Set the number of versions to keep.
$VersionsToKeep = 100
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
        If(($TotalVersions -gt $VersionsToKeep) -and ($Totalsize -gt $DeleteOverMb))
        {
              Write-Host -f Green "`t `tCleaning Up File:"$file.Name" (using $Totalsize Mb with $TotalVersions Versions)"
              For($i=0; $i -lt $VersionsToDelete; $i++)
              {
              ##Write-Host -f Cyan "`tCleaning Up File: "$file.Name" (using $Totalsize Mb) - Deleting The Oldest Version:" $Versions[0].VersionLabel
              $Versions[0].DeleteObject()
              }
              #$Ctx.ExecuteQuery()
              #Write-Host -f Red "Done"
            
        }
        else { Write-host -f Yellow "`tSkipping:"$File.Name"  - $TotalVersions Versions and $Totalsize Mb "  }

    }

}

$SPFolder = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderServerRelativeURL -Recursive -ItemType File
Cleanup-Versions -Folder $SPFolder

#Completely re-written, but with some help from here: https://www.sharepointdiary.com/2018/05/sharepoint-online-delete-version-history-using-pnp-powershell.html#ixzz7HwEq9cp3
