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
                if($DBgroups.ObjectGUID -contains $group.ObjectGUID -and $DBgroups.CommonName -contains $group.Name){
                    Write-Verbose "Updating Group in Reference DB: $group"
                    Update-WRADGroup -Reference -ObjectGUID:$group.ObjectGUID -CommonName:$group.Name -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope
                }
                else{
                    Write-Verbose "Write New Group to Reference DB: $group"
                    New-WRADGroup -Reference -CommonName:$group.Name -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope
                }
            }
            ## Write Group in Group Memberships to Reference DB
            Write-Verbose "START writing Group in Group Membership to Reference DB";
            ForEach($group in $csvData){
                $ParentObjectGUIDs = $group.Membership -split ";" | Get-WRADGroup -Reference -CommonName:$_ # tbd.
                if(!$group.ObjectGUID){
                    $group.ObjectGUID = $(Get-WRADGroup -Reference -CommonName:$group.Name).ObjectGUID
                }
                foreach($parentObjectGUID in $ParentObjectGUIDs){
                    $alreadyExisting = Get-WRADGroupOfGroup -Reference -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$parentObjectGUID.ObjectGUID
                    if(!$alreadyExisting){
                        New-WRADGroupOfGroup -Reference -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$parentObjectGUID.ObjectGUID
                    }
                }
                ## Delete the removed Group Memberships from DB
                $DBexistinggroupofgroup = $DBgroupofgroup | Where ChildGroupObjectGUID -eq $group.ObjectGUID
                foreach($t in $DBexistinggroupofgroup){
                    if($ParentObjectGUIDs.ObjectGUID -notcontains $t.ParentGroupObjectGUID){
                        Remove-WRADGroupOfGroup -Reference -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$t.ParentGroupObjectGUID
                    }
                }
            }
            ## Delete csv removed Groups from DB
            Write-Verbose "START cleaning up DB. Deleting the removed groups from Reference DB.";
            foreach($group in $DBgroups){
                if($csvData.ObjectGUID -notcontains $group.ObjectGUID){
                    # still existing memberships dont have to be checked, the deletion cascades to the memberships
                    Write-Verbose "REMOVING group from Reference DB: $group"
                    Remove-WRADGroup -ObjectGUID:$group.ObjectGUID
                }
            }
        }

        ### write SOLL User Data into Reference DB
        if($ImportAs -eq 'Users')
        {
            [Boolean]$csvData.Enabled = $csvData.Enabled
            Write-Verbose "START writing Users from csv to Reference DB";
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
                    # still existing memberships dont have to be checked, the deletion cascades to the memberships
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