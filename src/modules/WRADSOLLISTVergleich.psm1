function Invoke-WRADSOLLISTVergleich{
    # import DB module
    try
	{
		Write-Verbose "Loading PS Module WRADDBCommands"
		Import-Module -Name ($PSScriptRoot+"\WRADDBCommands.psd1")
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}

    # Get Data
    $usersIST = Get-WRADUser
    $usersRef = Get-WRADUser -Reference
    $groupsIST = Get-WRADGroup
    $groupsRef = Get-WRADGroup -Reference
    $usergroupsIST = Get-WRADGroupOfUser
    $usergroupsRef = Get-WRADGroupOfUser -Reference
    $groupgroupsIST = Get-WRADGroupOfGroup
    $groupgroupsRef = Get-WRADGroupOfGroup -Reference

    $ERR_users_not_in_SOLL = @()
    $ERR_users_not_in_IST = @()
    $ERR_users_displayname = @()
    $ERR_users_enabled = @()
    $ERR_groups_not_in_SOLL = @()
    $ERR_groups_not_in_IST = @()
    $ERR_groups_grouptype = @()
    $ERR_groups_grouptypesecurity = @()
    $ERR_usergroups_user_not_in_group = @()
    $ERR_usergroups_user_in_group = @()
    $ERR_groupgroups_group_not_in_group = @()
    $ERR_groupgroups_group_in_group = @()

    # Do User Comparison
    foreach($uIST in $usersIST){
        
    }
    
    <#
    .SYNOPSIS

    Compare IST with SOLL (Reference with current)

    .DESCRIPTION

    Compare IST with SOLL (Reference with current)

    .INPUTS



    .OUTPUTS

    Fills the Ref table with data from RefNew

    .EXAMPLE

    C:\PS> Write-RefFromRefNew
    
    #>
}