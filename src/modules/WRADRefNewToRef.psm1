function Write-RefFromRefNew{
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
    
    # empty ref
    Clear-WRADReference -Force

    # get data
    $users_ref_new = Get-WRADUser -NewReference
    $groups_ref_new = Get-WRADGroup -NewReference
    $usergroup_ref_new = Get-WRADGroupOfUser -NewReference
    $groupgroup_ref_new = Get-WRADGroupOfGroup -NewReference

    # mapping for ID -> GUID
    $map_refnewuser = @{}
    $map_refnewgroup = @{}

    # loop through users
    foreach ($u_ref_new in $users_ref_new){
        # try to get GUID from IST
        $username = $u_ref_new.Username
        $guid = ""
        $user_ist = Get-WRADUser -UserPrincipalName $username
        # if no user found, set guid to noguidXX else to the actual guid
        if (!$user_ist){
            $guid = "noguid"+$u_ref_new.NewUserID
        } else {
            $guid = ""+$user_ist.ObjectGUID
        }
        # add entry to map
        $map_refnewuser.add($u_ref_new.NewUserID, $guid)
        # add user to ref
        New-WRADUser -Reference -ObjectGUID $guid -Username $username -DisplayName $u_ref_new.DisplayName -Enabled $u_ref_new.Enabled
    }
    # loop through groups
    foreach ($g_ref_new in $groups_ref_new){
        # try to get GUID from IST
        $groupname = $g_ref_new.CommonName
        $guid = ""
        $group_ist = Get-WRADGroup -CommonName $groupname
        # if no group found, set guid to noguidXX else to the actual guid
        if (!$group_ist){
            $guid = "noguid"+$g_ref_new.NewGroupID
        } else {
            $guid = ""+$group_ist.ObjectGUID
        }
        # add entry to map
        $map_refnewgroup.add($g_ref_new.NewGroupID, $guid)
        # add group to ref
        New-WRADGroup -Reference -ObjectGUID $guid -CommonName $groupname -GroupType $g_ref_new.GroupType -GroupTypeSecurity $g_ref_new.GroupTypeSecurity
    }
    # loop through user/group objects
    foreach ($ug_ref_new in $usergroup_ref_new){
        # read guids from map
        $u_guid = $map_refnewuser[$ug_ref_new.NewUserID]
        $g_guid = $map_refnewgroup[$ug_ref_new.NewGroupID]
        # add user/group to ref
        New-WRADGroupOfUser -Reference -UserObjectGUID $u_guid -GroupObjectGUID $g_guid
    }
    foreach ($gg_ref_new in $groupgroup_ref_new){
        # read guids from map
        $c_guid = $map_refnewgroup[$gg_ref_new.NewChildGroupID]
        $p_guid = $map_refnewgroup[$gg_ref_new.NewParentGroupID]
        # add group/group to ref
        New-WRADGroupOfGroup -Reference -ChildGroupObjectGUID $c_guid -ParentGroupObjectGUID $p_guid
    }

    
    
    <#
    .SYNOPSIS

    Fill the Ref table

    .DESCRIPTION

    Fill the Ref table with data from RefNew

    .INPUTS



    .OUTPUTS

    Fills the Ref table with data from RefNew

    .EXAMPLE

    C:\PS> Write-RefFromRefNew
    
    #>
}