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
Description       : blablabla
Enabled           : True
createTimeStamp   : 9/26/2018 10:45:13 AM
Modified          : 9/26/2018 10:45:13 AM
LastLogonDate     : 9/26/2018 11:37:22 AM
MemberOf          : {CN=Marketing Coordinator - Utah,OU=Groups,OU=WRAD,DC=WRAD,DC=local}
#>


function Get-WRADADGroups
{
	Param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$searchbase
	)

	try 
	{
		Get-ADGroup -Filter * -SearchBase:$searchbase -Properties * | Select-Object ObjectGUID,DistinguishedName,Name,SamAccountName,GroupCategory,GroupScope,Members,MemberOf,Description
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
	Param(
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

	$searchbase = "OU=WRAD,DC=WRAD,DC=local"  # Get-WRADSetting | Where SettingName -like "Searchbase" | Select-Object SettingValue   #t.d. Setting aus DB auslesen
	$filter = "*"  #nicht nötig aus DB zu holen, einfach alle Rohdaten auslesen, filtering wird später gemacht
	$ADusers = Get-WRADADUsers -filter:$filter -searchbase:$searchbase 
	$ADgroups = Get-WRADADGroups -searchbase:$searchbase
    $today = Get-Date

	$DBusers = Get-WRADUser
	$DBgroups = Get-WRADGroup

	try
	{
		### Write Groups from AD to DB
		Write-Verbose "Write Groups from AD to DB";
		ForEach($group in $ADgroups){
			if($DBgroups.ObjectGUID -contains $group.ObjectGUID){
				Update-WRADGroup -ObjectGUID:$group.ObjectGUID -SAMAccountName:$group.SamAccountName -CommonName:$group.Name -DistinguishedName:$group.DistinguishedName -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope -Description:$group.Description
			}
			else{
				New-WRADGroup -ObjectGUID:$group.ObjectGUID -SAMAccountName:$group.SamAccountName -CommonName:$group.Name -DistinguishedName:$group.DistinguishedName -GroupTypeSecurity:$group.GroupCategory -GroupType:$group.GroupScope -Description:$group.Description
			}
		}
		### Write Group in Group Membership to DB
		Write-Verbose "Write Group in Group Membership to DB";
		ForEach($group in $ADgroups){
			$ParentObjectGUIDs = $group.MemberOf | Get-ADGroup | Select-Object ObjectGUID
			foreach($parentObjectGUID in $ParentObjectGUIDs){
				New-WRADGroupOfGroup -ChildGroupObjectGUID:$group.ObjectGUID -ParentGroupObjectGUID:$parentObjectGUID
			}
			
		}
		### Write Users from AD to DB
		Write-Verbose "Write Users from AD to DB";
		ForEach($user in $ADusers){
			## Set the right value for expired accounts
            if($user.accountExpires -eq '9223372036854775807'){ ## Default Value for never expires
                $expired = $FALSE
            }
            elseif($today -gt ([datetime]::FromFileTime($user.accountExpires))){
                $expired = $TRUE
            }
            else{
                $expired = $FALSE
			}
			
			## Actually write/update Users to DB
			if($DBusers.ObjectGUID -contains $user.ObjectGUID){
				Update-WRADUser -ObjectGUID:$user.ObjectGUID -SAMAccountName:$user.SamAccountName -DistinguishedName:$user.DistinguishedName -UserPrincipalName:$user.UserPrincipalName -DisplayName:$user.DisplayName -Description:$user.Description -LastLogonTimestamp:$user.LastLogonDate -Enabled:$user.Enabled
			}
			else{
                
                New-WRADUser -ObjectGUID:$user.ObjectGUID -SAMAccountName:$user.SamAccountName -DistinguishedName:$user.DistinguishedName -UserPrincipalName:$user.UserPrincipalName -DisplayName:$user.DisplayName -Description:$user.Description -LastLogonTimestamp:$user.LastLogonDate -Enabled:$user.Enabled -Expired:$expired
			}

			### Write User in Group Membership to DB
			$GroupObjectGUIDs = $user.MemberOf | Get-ADGroup | Select-Object ObjectGUID
			foreach($GroupObjectGUID in $GroupObjectGUIDs){
				New-WRADGroupOfUser -UserObjectGUID:$user.ObjectGUID -GroupObjectGUID:$GroupObjectGUID
			}
		}
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}
}


#Example function calls
#Get-WRADADUsers -filter 'Name -like "*Thor*"' -searchbase "OU=WRAD,DC=WRAD,DC=local"
#Get-WRADADGroups -searchbase "OU=WRAD,DC=WRAD,DC=local"
#Write-WRADISTtoDB