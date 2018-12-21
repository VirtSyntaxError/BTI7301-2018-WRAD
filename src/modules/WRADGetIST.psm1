function Get-WRADADUsers
{
    Param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$filter, 
		
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [String]$searchbase
	)

	try
	{
		Get-ADUser -Filter:$filter -SearchBase:$searchbase -Properties:* |  Select-Object ObjectGUID,DisplayName,SaMAccountName,UserPrincipalName,DistinguishedName,Description,Enabled,LastLogonDate,MemberOf,accountExpires
	}
	catch
	{
		Write-Error -Message $_.Exception.Message
	}
}
<#
Output Example

ObjectGUID        : 6deb88d9-8255-483d-990e-29e1029dd19a
DisplayName       : Agatha S Thornton
SaMAccountName    : Agatha.S.Thornton
UserPrincipalName : Agatha.S.Thornton@WRAD.local
DistinguishedName : CN=Agatha S Thornton,OU=Marketing,OU=Utah,OU=WRAD,DC=WRAD,DC=local
Description       : blabla
Enabled           : True
LastLogonDate     : 10/23/2018 4:27:54 PM
MemberOf          : {CN=Marketing Coordinator - Utah,OU=Groups,OU=WRAD,DC=WRAD,DC=local}
accountExpires    : 9223372036854775807
#>


function Get-WRADADGroups
{
	Param(
	)

	try 
	{
		Get-ADGroup -Filter * -Properties * | Select-Object ObjectGUID,DistinguishedName,Name,SamAccountName,GroupCategory,GroupScope,Members,MemberOf,Description
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}
}
<#
Output Example

ObjectGUID        : 7ccaae78-4582-46bf-a78a-bfcc931f2aca
DistinguishedName : CN=Project Management Senior Project Manager - Utah,OU=Groups,OU=WRAD,DC=WRAD,DC=local
Name              : Project Management Senior Project Manager - Utah
SamAccountName    : Project Management Senior Project Manager - Utah
GroupCategory     : Security
GroupScope        : Universal
Members           : {CN=Eryn J Higdon,OU=Project Management,OU=Utah,OU=WRAD,DC=WRAD,DC=local}
MemberOf          : {CN=Project Management Senior Project Manager,OU=Groups,OU=WRAD,DC=WRAD,DC=local}
Description       : blablabla
#>


function Write-WRADISTtoDB
{
	[cmdletbinding()] # needed for the Verbose function
	Param(
	)

	try 
	{
		Write-Verbose "Loading WRAD Custom PS Modules";
		Import-Module $PSScriptRoot\WRADDBCommands.psd1
		Import-Module $PSScriptRoot\WRADLogging.psd1
		Write-Verbose "Loading PS Module ActiveDirectory";
		Import-Module ActiveDirectory
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}

	### Set helper Variables
	$filter = "*"  #nicht nötig aus DB zu holen, einfach alle Rohdaten auslesen, filtering wird später gemacht
	$today = Get-Date
	
	### set AD searchbase to either DB-Setting or if empty to AD Root
	$DBsearchbase = (Get-WRADSetting | Where SettingName -like "Searchbase").SettingValue
	If($DBsearchbase){
		$searchbase = $DBsearchbase
	}
	else {
		$searchbase = (Get-ADRootDSE).rootDomainNamingContext
	}

	### Get actual AD Users and Groups from AD
	$ADusers = Get-WRADADUsers -filter:$filter -searchbase:$searchbase 
	$ADgroups = Get-WRADADGroups

	### Get all DB content for the IS-situation
	$DBusers = Get-WRADUser
	$DBgroups = Get-WRADGroup
	$DBgroupofgroup = Get-WRADGroupOfGroup
	$DBgroupofuser = Get-WRADGroupOfUser

	try
	{
		### Write/update Groups from AD to DB
		Write-Verbose "START writing Groups from AD to DB";
		ForEach($group in $ADgroups){
			if($DBgroups.ObjectGUID -contains $group.ObjectGUID){
				Write-Verbose "Updating Group in DB: $group"
				Update-WRADGroup -ObjectGUID:$group.ObjectGUID -SAMAccountName:$group.SamAccountName -CommonName:$group.Name -DistinguishedName:$group.DistinguishedName -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope -Description:$group.Description
			}
			else{
				Write-Verbose "Write New Group to DB: $group"
				New-WRADGroup -ObjectGUID:$group.ObjectGUID -SAMAccountName:$group.SamAccountName -CommonName:$group.Name -DistinguishedName:$group.DistinguishedName -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope -Description:$group.Description
			}
		}
		Write-Verbose "FINISHED writing Groups to DB"

		### Write Group in Group Membership to DB
		Write-Verbose "START writing Group in Group Membership to DB";
		ForEach($group in $ADgroups){
			$ParentObjectGUIDs = $group.MemberOf | Get-ADGroup | Select-Object ObjectGUID
			foreach($parentObjectGUID in $ParentObjectGUIDs){
				$alreadyExisting = Get-WRADGroupOfGroup -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$parentObjectGUID.ObjectGUID
				if(!$alreadyExisting){
					New-WRADGroupOfGroup -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$parentObjectGUID.ObjectGUID
				}
			}
			## Delete the removed Group Memberships from DB
			$DBexistinggroupofgroup = $DBgroupofgroup | Where ChildGroupObjectGUID -eq $group.ObjectGUID
			foreach($t in $DBexistinggroupofgroup){
				if($ParentObjectGUIDs.ObjectGUID -notcontains $t.ParentGroupObjectGUID){
					Remove-WRADGroupOfGroup -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$t.ParentGroupObjectGUID
				}
			}
		}
		Write-Verbose "FINISHED writing Group of Group Membership to DB"
		Write-WRADLog 'Updated Groups IST DB from AD' 0

		### Write Users from AD to DB
		Write-Verbose "START writing Users from AD to DB";
		ForEach($user in $ADusers){
			## Set the right value for expired accounts
            if($user.accountExpires -eq '9223372036854775807'){ ## Default Value for never expires
                $expired = $FALSE
            }
            elseif($today -gt ([DateTime]::FromFileTime($user.accountExpires))){
                $expired = $TRUE
            }
            else{
                $expired = $FALSE
			}

            ## Bug Enabled is not shown -> set to true
            if($user.Enabled -eq "") {
                [boolean]$enabled = $TRUE
            } else {
                [boolean]$enabled = $user.Enabled
            }

			## Actually write/update Users to DB
			if($DBusers.ObjectGUID -contains $user.ObjectGUID){
				Write-Verbose "Updating User to DB: $user"
				Update-WRADUser -ObjectGUID:$user.ObjectGUID -SAMAccountName:$user.SamAccountName -DistinguishedName:$user.DistinguishedName -UserPrincipalName:$user.UserPrincipalName -DisplayName:$user.DisplayName -Description:$user.Description -LastLogonTimestamp:$user.LastLogonDate -Enabled:$enabled -Expired:$expired
			}
			else{
				Write-Verbose "Writing new User to DB: $user"
                New-WRADUser -ObjectGUID:$user.ObjectGUID -SAMAccountName:$user.SamAccountName -DistinguishedName:$user.DistinguishedName -UserPrincipalName:$user.UserPrincipalName -DisplayName:$user.DisplayName -Description:$user.Description -LastLogonTimestamp:$user.LastLogonDate -Enabled:$enabled -Expired:$expired
			}

			## Write User in Group Membership to DB
			Write-Verbose "START writing new Group Memership of User: $($user.ObjectGUID)"
			$GroupObjectGUIDs = $user.MemberOf | Get-ADGroup | Select-Object ObjectGUID
			foreach($GroupObjectGUID in $GroupObjectGUIDs){
				$alreadyExisting = Get-WRADGroupOfUser -UserObjectGUID:$user.ObjectGUID -GroupObjectGUID:$GroupObjectGUID.ObjectGUID
				if(!$alreadyExisting){
					New-WRADGroupOfUser -UserObjectGUID:$user.ObjectGUID -GroupObjectGUID:$GroupObjectGUID.ObjectGUID
				}
			}
			## Delete the removed User in Group Memberships from DB
			$DBexistinggroupofuser = $DBgroupofuser | Where UserObjectGUID -eq $user.ObjectGUID
			foreach($t in $DBexistinggroupofuser){
				if($GroupObjectGUIDs.ObjectGUID -notcontains $t.GroupObjectGUID){
					Remove-WRADGroupOfUser -UserObjectGUID:$user.ObjectGUID -GroupObjectGUID:$t.GroupObjectGUID
				}
			}
		}
		Write-Verbose "FINISHED writing Users to DB";

		### Delete removed Users from DB
		Write-Verbose "START cleaning up DB. Deleting the removed users/groups from DB.";
		foreach($user in $DBusers){
			if($ADusers.ObjectGUID -notcontains $user.ObjectGUID){
				Write-Verbose "REMOVING user from DB: $user"
				Remove-WRADUser -ObjectGUID:$user.ObjectGUID
			}
		}
		### Delete removed Groups from DB
		foreach($group in $DBgroups){
			if($ADgroups.ObjectGUID -notcontains $group.ObjectGUID){
				Write-Verbose "REMOVING group from DB: $group"
				Remove-WRADGroup -ObjectGUID:$group.ObjectGUID
			}
		}
		Write-Verbose "FINISHED cleaning up DB";
		Write-WRADLog 'Updated Users IST DB from AD' 0
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
		Write-WRADLog 'failed to updates IST DB from AD' 2
	}
	<#
    .SYNOPSIS

    Exports Data from AD to a DB

    .DESCRIPTION

    Exports the actual User and Group Data from Active Directory to the WRAD DB.

    .INPUTS
    
    None. You cannot pipe objects to this function.

    .OUTPUTS

    No direct output, but Data gets Stored in DB

    .EXAMPLE

    C:\PS> Write-WRADISTtoDB

    #>
}
