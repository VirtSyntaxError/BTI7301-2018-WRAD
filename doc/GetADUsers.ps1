
function Get-ADNestedGroupMembership
{
	Param(
		[Parameter(Mandatory=$true)]
		[String]$strADObject,
		[String[]]$parents = @()
	)
	
	foreach ($group in Get-ADPrincipalGroupMembership -Identity:$strADObject)
	{
		if ($parents -inotcontains $group.DistinguishedName)
		{
			Write-Output $group.Name
			Get-ADNestedGroupMembership -strADObject:$group.DistinguishedName -parents:($parents + $group.DistinguishedName)
		}
	}
}


function GetADUsers
{
    Param(
        [Parameter(Mandatory=$true)]
        [String]$filter, 
        [String]$searchbase
    )
    
    Get-ADUser -Filter:$filter -SearchBase:$searchbase -Properties:* | ForEach-Object {
    $user = $_
	$parents = Get-ADPrincipalGroupMembership -Identity:$_.DistinguishedName
	$parentNames = $parents | Select-Object -ExpandProperty 'name'
	foreach ($parent in $parents)
	{
		$parentNames += Get-ADNestedGroupMembership -strADObject:($parent.DistinguishedName) -parents:($parents | Select-Object -ExpandProperty 'DistinguishedName')
	}
    $user.AllGroups = $parentNames
	$user | Select *
}


}

#Example function call
GetADUsers -filter 'Name -like "*Archer"' -searchbase "OU=WRAD,DC=WRAD,DC=local"