function Import-WRADcsv
{
	[cmdletbinding()] # needed for the Verbose function
	Param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ })]
        [String]$csvPath,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Users','Groups')]
		[string]$ImportAs
    )
    
    try 
	{
		Write-Verbose "Loading PS Module WRADDBCommands";
		Import-Module $PSScriptRoot\WRADDBCommands.psd1
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
    }
    

    try
    {
        $csvData = Import-Csv -Path:$csvPath
        ### Get all DB content for the SOLL-situation
        $DBusers = Get-WRADUser -Reference
        $DBgroups = Get-WRADGroup -Reference
        $DBgroupofgroup = Get-WRADGroupOfGroup -Reference
        $DBgroupofuser = Get-WRADGroupOfUser -Reference

        ### validate csv Input, for every column
        

        ### write SOLL Group Data into Reference DB
        Write-Verbose "START writing Groups from csv to Reference DB";
        if($ImportAs -eq 'Groups'){
            foreach($group in $csvData){
                if($DBgroups.ObjectGUID -contains $group.ObjectGUID){
                    Write-Verbose "Updating Group in Reference DB: $group"
                    Update-WRADGroup -Reference -ObjectGUID:$group.ObjectGUID -CommonName:$group.Name -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope
                }
                else{
                    Write-Verbose "Write New Group to Reference DB: $group"
                    New-WRADGroup -Reference -CommonName:$group.Name -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope
                }
            }
            ## Write Group in Group Memberships to Reference DB
            
            ## Delete csv removed Groups from DB
            Write-Verbose "START cleaning up DB. Deleting the removed groups from Reference DB.";
            foreach($group in $DBgroups){
                if($csvData.ObjectGUID -notcontains $group.ObjectGUID){
                    # tbd. check if there are still existing group memberships, if yes throw error to first update the memberships
                    Write-Verbose "REMOVING group from Reference DB: $group"
                    Remove-WRADGroup -ObjectGUID:$group.ObjectGUID
                }
            }
        }

        ### write SOLL User Data into Reference DB
        Write-Verbose "START writing Users from csv to Reference DB";
        if($ImportAs -eq 'Users'){
            foreach($user in $csvData){
                if($DBusers.ObjectGUID -contains $user.ObjectGUID){
                    Write-Verbose "Updating User to Reference DB: $user"
                    Update-WRADUser -ObjectGUID:$user.ObjectGUID -UserName:$user.UserPrincipalName -DisplayName:$user.DisplayName -Enabled:$user.Enabled
                }
                else{
                    Write-Verbose "Writing new User to Reference DB: $user"
                    New-WRADUser -Reference -UserName:$user.UserPrincipalName -DisplayName:$user.DisplayName -Enabled:$user.Enabled
                }
            }
            ## Write User in Group Memberships to Reference DB

            
            ## Delete csv removed Users from DB
            Write-Verbose "START cleaning up DB. Deleting the removed users from Reference DB.";
            foreach($user in $DBusers){
                if($csvData.ObjectGUID -notcontains $user.ObjectGUID){
                    # tbd. check if there are still existing group memberships, if yes throw error to first update the memberships
                    Write-Verbose "REMOVING user from Reference DB: $user"
                    Remove-WRADUser -Reference -ObjectGUID:$user.ObjectGUID
                }
            }
        }
    }
    catch
    {
        Write-Error -Message $_.Exception.Message
    }
}
# Example Function Call
#Import-WRADcsv -csvPath "C:\Code\BFH.WRAD\doc\ImportTemplateUser.csv" -ImportAs "Users"