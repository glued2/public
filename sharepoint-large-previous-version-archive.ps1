###Setup PC
#   #[As Admin]
#   Set-ExecutionPolicy -ExecutionPolicy Unrestricted
#   #
##pwsh.exe
#Update-Module PnP.Powershell
#Install-Module -Name PnP.Powershell -force


#First Connect - this can be done manually...
Connect-PnPOnline -Url https://[sitename].sharepoint.com/sites/[site] -UseWebLogin
#Disconnect-PnPOnline


#Set the number of versions to keep.
$PreviousVersionsToKeep = 5
#Old versions is hard coded to be anything more than a year old.
$OldPreviousVersionsToKeep = 2
#Delete Previous Versions where the total size is over xxxMb (1024 - means only files over 1Gb will be targetted)
#This is the measure of the current versions size - not the previous versions or the total! 
$DeleteOverMb = 50

#
Function Cleanup-Versions($folder)
{ 
    #Iterate through each file passed in the query. 
    ForEach ($File in $folder)
    {
        #Get File Versions
        $Versions = Get-PnPProperty -ClientObject $File -Property Versions        
        $TotalVersions = $Versions.Count


## Going to work out if we should apply old or new logic:-  
        if ($TotalVersions -ge $OldPreviousVersionsToKeep){
        #Might need to delete these versions based on age of file.... 
        $LastModified = Get-PnPProperty -ClientObject $File -Property TimeLastModified
          if ($LastModified -lt $OldDate){ 
            #Write-Host -f Green "Old File Found: " $File.Name " - being ruthless with the $TotalVersions versions"
            $oldindicator = "last modified over a year ago"
            $versiondecision = $OldPreviousVersionsToKeep
          }
          else { 
            #Write-Host -f Yellow "Not too old $File - so will be less ruthless" 
            $versiondecision = $PreviousVersionsToKeep
            $oldindicator = "last modified this year"
          }
        }
    #Now we know how many versions to remove:- 
        $VersionsToDelete = $TotalVersions - $versiondecision
 
       $rawsize = $Versions | Measure-Object -Property Size -Sum | Select-Object -expand Sum
       $Totalsize = [Math]::Round(($rawsize/1048576),2)
       $originalfilesizeb = Get-PnPProperty -ClientObject $File -Property Length
       $originalfilesizemb = [Math]::Round(($originalfilesizeb/1048576),2)
       ##Write-Host "File: " $File.Name " With $TotalSize Mb - in $TotalVersions and an original file size of $originalfilesizemb ($originalfilesizeb) "

        ##Write-Host -f Green "`t `t"$File.Name" has $TotalVersions - so I will keep $PreviousVersionsToKeep - with $VersionsToDelete to delete - its $size MB and $singversionrawsize MB big" 
        ## No longer need to do file size check here.  
        ##  If(($TotalVersions -gt $PreviousVersionsToKeep) -and ($Totalsize -gt $DeleteOverMb))

        If(($TotalVersions -gt $versiondecision) -and ($Totalversions -ne 0))
        {            
              Write-Host -f Green "`t `t"$File.Name" - $oldindicator  is: $originalfilesizemb Mb with $TotalVersions versions using $Totalsize Mb - will keep $versiondecision - with $VersionsToDelete to delete its $Totalsize Mb too big!" 
              For($i=0; $i -lt $VersionsToDelete; $i++)
              {
               #This is the delete command!!!
              $Versions[0].DeleteObject()
              }
              ##Now we've deleted, we'll check how many versions, what we have and what we've saved:-  
              $newpreviousversions = Get-PnPProperty -ClientObject $File -Property Versions
              $newpreviousversionssize = $newpreviousversions | Measure-Object -Property Size -Sum | Select-Object -expand Sum
              $savedsize = $rawsize - $newpreviousversionssize
              $global:TotalDeleted = $global:TotalDeleted + $savedsize
        }
        else {   #Write-host -f Cyan "`tSkipping:"$File.Name"  - $TotalVersions Versions using $Totalsize and the original file using $originalfilesizemb Mb - but $versiondecision is keep (total: $TotalDeleted)"  
           }
    }

}

Function Get-LargeFileList ($FolderServerRelativeURL)
{ 
  if ($DirectoryList = Get-PnPFolderInFolder $FolderServerRelativeURL) {
    foreach ($List in $DirectoryList)
    { 
     $Name = Get-PnPProperty -ClientObject $List -Property Name
     $ThisFolder = "$FolderServerRelativeURL/$Name"
     ###  Write-Host -f Yellow "`tScanning Directory:"$ThisFolder
     #Object Length is the measure of the _current_ version - not the total of all history;  We only refer larger current files, to the cleanup.   
     Get-LargeItemListandcallCleanup ($ThisFolder)
    }
  }
  else { 
    Get-LargeItemListandcallCleanup ($FolderServerRelativeURL)
    Write-Host -f Yellow "`tNo sub-directories found - scan complete. " $SPFolder.count " oversize files found."  
  }
}


Function Get-LargeItemListandcallCleanup ($folder)
{  
    Write-Host "Folder to scan: $folder"
    $SPFolder = Get-PnPFolderItem  -FolderSiteRelativeUrl $folder -Recursive -ItemType File  |  Where-Object {$_.Length -gt $DeleteOverBytes}  
    Cleanup-Versions $SPFolder 
}



#Split Directory to breakdown and try and speed up / provide feedback:
Function Site-Cleanup ($FolderServerRelativeURL){
  #Set Some Variables at run time:- 
  ##Variables we use later - dont change these:- 
  $global:TotalDeleted = 0
  $DeleteOverBytes = $DeleteOverMb * 1048576
  $Today = Get-Date
  $OldDate = $Today.AddDays(-365)
  ##
  Write-Host "Cleaning Up Previous Versions for $FolderServerRelativeURL"
  Get-LargeFileList $FolderServerRelativeURL
  $TotalDeletedMb = [Math]::Round(($TotalDeleted/1048576),2)
  Write-Host -f Red "Clean Up Complete with $TotalDeletedMb Mb saved."
}


Site-Cleanup "Shared Documents"


#Completely re-written, but with some help from here: https://www.sharepointdiary.com/2018/05/sharepoint-online-delete-version-history-using-pnp-powershell.html#ixzz7HwEq9cp3
