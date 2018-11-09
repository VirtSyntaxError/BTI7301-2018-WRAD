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
        # tbd.

        ### write SOLL Group Data into Reference DB
        if($ImportAs -eq 'Groups')
        {
            Write-Verbose "START writing Groups from csv to Reference DB";
            foreach($group in $csvData){
                if(!$group.ObjectGUID){
                    $group.ObjectGUID = $(Get-WRADGroup -Reference -CommonName:$group.Name).ObjectGUID
                }
                if($DBgroups.ObjectGUID -contains $group.ObjectGUID){
                    Write-Verbose "UPDATING Group in Reference DB: $group"
                    Update-WRADGroup -Reference -ObjectGUID:$group.ObjectGUID -CommonName:$group.Name -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope
                }
                else{
                    Write-Verbose "WRITING New Group to Reference DB: $group"
                    New-WRADGroup -Reference -CommonName:$group.Name -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope
                }
            }
            Write-Verbose "FINISHED writing Groups to Reference DB";

            ## Write Group in Group Memberships to Reference DB
            Write-Verbose "START writing Group in Group Membership to Reference DB";
            ForEach($group in $csvData){
                if(!$group.ObjectGUID){
                    $group.ObjectGUID = $(Get-WRADGroup -Reference -CommonName:$group.Name).ObjectGUID
                }
                Write-Verbose "WORKING on Memberships of: $group"
                if($group.Membership){
                    $ParentObjectGUIDs = $group.Membership -split ";" | %{Get-WRADGroup -Reference -CommonName:$_} # tbd.
                    Write-Verbose "Parent Groups: $($ParentObjectGUIDs.ObjectGUID)"
                    foreach($parentObjectGUID in $ParentObjectGUIDs){
                        $alreadyExisting = Get-WRADGroupOfGroup -Reference -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$parentObjectGUID.ObjectGUID
                        if(!$alreadyExisting){
                            Write-Verbose "WRITING New Group in group membership to Reference DB. Child:$($group.ObjectGUID), Parent:$($parentObjectGUID.ObjectGUID)"
                            New-WRADGroupOfGroup -Reference -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$parentObjectGUID.ObjectGUID
                        }
                    }
                }
                else {
                    $ParentObjectGUIDs = ""
                }
                ## Delete the csv removed Group Memberships from DB
                $DBexistinggroupofgroup = $DBgroupofgroup | Where ChildGroupObjectGUID -eq $group.ObjectGUID
                foreach($t in $DBexistinggroupofgroup){
                    if($ParentObjectGUIDs.ObjectGUID -notcontains $t.ParentGroupObjectGUID){
                        Write-Verbose "REMOVING group in group membership from Reference DB. Child:$($group.ObjectGUID), Parent:$($t.ParentGroupObjectGUID)"
                        Remove-WRADGroupOfGroup -Reference -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$t.ParentGroupObjectGUID
                    }
                }
            }
            Write-Verbose "FINISHED writing Group Memberships to Reference DB";

            ## Delete csv removed Groups from DB
            Write-Verbose "START cleaning up DB. Deleting the csv removed groups from Reference DB.";
            foreach($group in $DBgroups){
                if($csvData.Name -notcontains $group.CommonName){
                    # still existing memberships dont have to be checked, the deletion cascades to the memberships
                    Write-Verbose "REMOVING group from Reference DB: $($group.CommonName), $($group.ObjectGUID)"
                    Remove-WRADGroup -Reference -ObjectGUID:$group.ObjectGUID
                }
            }
            Write-Verbose "FINISHED cleaning up Group Reference DB";
        }

        ### write SOLL User Data into Reference DB
        if($ImportAs -eq 'Users')
        {
            [Boolean]$csvData.Enabled = $csvData.Enabled
            Write-Verbose "START writing Users from csv to Reference DB";
            foreach($user in $csvData){
                if(!$user.ObjectGUID){
                    $user.ObjectGUID = $(Get-WRADUser -Reference -UserName:$user.UserPrincipalName).ObjectGUID
                }
                if($DBusers.ObjectGUID -contains $user.ObjectGUID){
                    Write-Verbose "UPDATING User to Reference DB: $user"
                    Update-WRADUser -ObjectGUID:$user.ObjectGUID -UserName:$user.UserPrincipalName -DisplayName:$user.DisplayName -Enabled:$user.Enabled
                }
                else{
                    Write-Verbose "WRITING new User to Reference DB: $user"
                    New-WRADUser -Reference -UserName:$user.UserPrincipalName -DisplayName:$user.DisplayName -Enabled:$user.Enabled
                }

                ## Write User in Group Memberships to Reference DB
                if($user.Membership){
                    $GroupObjectGUIDs = $user.Membership -split ";" | %{Get-WRADGroup -Reference -CommonName:$_}
                    Write-Verbose "Memberof group: $($GroupObjectGUIDs.ObjectGUID)"
                    foreach($GroupObjectGUID in $GroupObjectGUIDs){
                        $alreadyExisting = Get-WRADGroupOfUser -Reference -UserObjectGUID:$user.ObjectGUID -GroupObjectGUID:$GroupObjectGUID.ObjectGUID
                        if(!$alreadyExisting){
                            Write-Verbose "WRITING new User in group membership to Reference DB. User:$($user.ObjectGUID), Group:$($GroupObjectGUID.ObjectGUID)"
                            New-WRADGroupOfUser -Reference -UserObjectGUID:$user.ObjectGUID -GroupObjectGUID:$GroupObjectGUID.ObjectGUID
                        }
                    }
                }
                else {
                    $GroupObjectGUID = ""
                }
                
                ## Delete the csv removed User in Group Memberships from DB
                $DBexistinggroupofuser = $DBgroupofuser | Where UserObjectGUID -eq $user.ObjectGUID
                foreach($t in $DBexistinggroupofuser){
                    if($GroupObjectGUIDs.ObjectGUID -notcontains $t.GroupObjectGUID){
                        Write-Verbose "REMOVING user in group membership from Reference DB. User:$($user.ObjectGUID), Group:$($t.GroupObjectGUID)"
                        Remove-WRADGroupOfUser -Reference -UserObjectGUID:$user.ObjectGUID -GroupObjectGUID:$t.GroupObjectGUID
                    }
                }
            }
            Write-Verbose "FINISHED writing Users to Reference DB";
            
            ## Delete csv removed Users from DB
            Write-Verbose "START cleaning up DB. Deleting the csv removed users from Reference DB.";
            foreach($user in $DBusers){
                if($csvData.UserPrincipalName -notcontains $user.UserName){
                    # still existing memberships dont have to be checked, the deletion cascades to the memberships
                    Write-Verbose "REMOVING user from Reference DB: $($user.UserName), $($user.ObjectGUID)"
                    Remove-WRADUser -Reference -ObjectGUID:$user.ObjectGUID
                }
            }
            Write-Verbose "FINISHED cleaning User Reference DB";
        }
    }
    catch
    {
        Write-Error -Message $_.Exception.Message
    }
}
# Example Function Call
#Import-WRADcsv -csvPath "C:\Code\BFH.WRAD\doc\ImportTemplateUser.csv" -ImportAs "Users"

function Export-WRADcsv
{
    [cmdletbinding()] # needed for the Verbose function
	Param(
        [Parameter(Mandatory=$true)]
        [String]$csvPath,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Users','Groups')]
        [string]$ExportOf,
        
        [Parameter(Mandatory=$false)]
        [Switch]$initial
    )
    
    try 
	{
		Write-Verbose "Loading WRAD Custom PS Module WRADDBCommands";
        Import-Module $PSScriptRoot\WRADDBCommands.psd1
        Write-Verbose "Loading WRAD Custom PS Module WRADGetIST";
		Import-Module $PSScriptRoot\WRADGetIST.psd1
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
    }

    try 
    {
        if($ExportOf -eq 'Groups')
        {
            if($initial)
            {
                ### do an initial Export directly from AD
                $DBgroups = Get-WRADADGroups
            }
            else 
            {
                
            }
        }
        if($ExportOf -eq 'Users')
        {
            if($initial)
            {
                ### do an initial Export directly from AD
                $ADusers = Get-WRADADUsers -filter * -searchbase:$((Get-ADRootDSE).rootDomainNamingContext)
            }
            else 
            {
                
            }
        }
    }
    catch 
    {
        Write-Error -Message $_.Exception.Message
    }
}