
function Get-WRADADNestedGroupMembership
{
	Param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$strADObject,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String[]]$parents = @()
	)
	
	try 
	{
		foreach ($group in Get-ADPrincipalGroupMembership -Identity:$strADObject)
		{
			if ($parents -inotcontains $group.DistinguishedName)
			{
				#Write-Output $group.Name
				Get-ADNestedGroupMembership -strADObject:$group.DistinguishedName -parents:($parents + $group.DistinguishedName)
			}
		}
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}
}

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
		Get-ADUser -Filter:$filter -SearchBase:$searchbase -Properties:* | ForEach-Object {
			$user = $_
			$parents = Get-ADPrincipalGroupMembership -Identity:$_.DistinguishedName
			$parentNames = $parents | Select-Object -ExpandProperty 'name'
			foreach ($parent in $parents)
			{
				$parentNames += Get-WRADADNestedGroupMembership -strADObject:($parent.DistinguishedName) -parents:($parents | Select-Object -ExpandProperty 'DistinguishedName')
			}
			$user.AllGroups = $parentNames
			$user | Select-Object ObjectGUID,DisplayName,SaMAccountName,DistinguishedName,Description,Title,Enabled,createTimeStamp,Modified,LastLogonDate,MemberOf,AllGroups
		}
	}
	catch
	{
		Write-Error -Message $_.Exception.Message
	}
}

function Get-WRADADGroups
{
	Param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$searchbase
	)

	try 
	{
		Get-ADGroup -Filter * -SearchBase:$searchbase | Select-Object ObjectGUID,DistinguishedName,Name,SamAccountName,GroupCategory,GroupScope
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}
}

function Write-WRADISTtoDB
{
	Param(

	)

	try 
	{
		Import-Module .\WRADDBCommands.psd1
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}
	
	try{
		$searchbase = "OU=WRAD,DC=WRAD,DC=local"  #t.d. Setting aus DB auslesen
		$filter = *  #t.d. Setting aus DB auslesen
		$ADusers = Get-WRADADUsers -filter:$filter -searchbase:$searchbase 
		$ADgroups = Get-WRADADGroups -searchbase:$searchbase

		$DBusers = WRADDBCommands.Get-WRADUser
		$DBgroups = WRADDBCommands.Get-WRADGroup

		ForEach($user in $ADusers){
			if($DBusers.ObjectGUID -contains $user.ObjectGUID){
				WRADDBCommands.Update-WRADUser -ObjectGUID $user.ObjectGUID -SAMAccountName $user.SamAccountName -DistinguishedName $user.DistinguishedName -UserPrincipalName $user.UserPrincipalName -DisplayName $user.DisplayName -Description $user.Description -LastLogonTimestamp $user.LastLogonDate
			}
			else{
				WRADDBCommands.New-WRADUser -ObjectGUID $user.ObjectGUID -SAMAccountName $user.SamAccountName -DistinguishedName $user.DistinguishedName -UserPrincipalName $user.UserPrincipalName -DisplayName $user.DisplayName -Description $user.Description -LastLogonTimestamp $user.LastLogonDate
			}
		}
		ForEach($group in $ADgroups){
			if($DBgroups.ObjectGUID -contains $group.ObjectGUID){
				WRADDBCommands.Update-WRADGroup
			}
			else{
				WRADDBCommands.New-WRADGroup -ObjectGUID $group.ObjectGUID -SAMAccountName $group.SamAccountName -CommonName $group.CommonName -DistinguishedName $group.DistinguishedName -GroupTypeSecurity ... -GroupType $group.GroupCategory
			}
		}
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}
}


#Example function call
#Get-WRADADUsers -filter 'Name -like "*Archer"' -searchbase "OU=WRAD,DC=WRAD,DC=local"
