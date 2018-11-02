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
    $usersRefNoGUID = Get-WRADUser -Reference -NoObjectGUID
    $groupsIST = Get-WRADGroup
    $groupsRef = Get-WRADGroup -Reference
    $groupsRefNoGUID = Get-WRADGroup -Reference -NoObjectGUID
    $usergroupsIST = Get-WRADGroupOfUser
    $groupgroupsIST = Get-WRADGroupOfGroup
    # here only the ones referring users and groups that exist
    $usergroupsRef = Get-WRADGroupOfUser -Reference -ExistentObjectGUID
    $groupgroupsRef = Get-WRADGroupOfGroup -Reference -ExistentObjectGUID

    # define empty error array
    $ERR_list = @()
    <#
    user ist loop:
    1$ERR_users_not_in_SOLL = @()
    3$ERR_user_username = @()
    4$ERR_users_displayname = @()
    5$ERR_users_enabled = @()
    getnoguid refusers:
    2$ERR_users_not_in_IST = @()
    group ist loop:
    6$ERR_groups_not_in_SOLL = @()
    8$ERR_group_groupname = @()
    9$ERR_groups_grouptype = @()
    10$ERR_groups_grouptypesecurity = @()
    getnoguid refgroup:
    7$ERR_groups_not_in_IST = @()
    loop through usergroupref:
    11$ERR_usergroups_user_not_in_group = @()
    loop through usergroup:
    12$ERR_usergroups_user_in_group = @()

    loop through groupgroupref:
    13$ERR_groupgroups_group_not_in_group = @()
    loop through groupgroup:
    14$ERR_groupgroups_group_in_group = @()#>

    # Do User Comparison
    foreach($uIST in $usersIST){
        # get UPN
        $username_upn = $uIST.userPrincipalName
        # get UPN without domain
        $username = $username_upn.Substring(0,$username.IndexOf("@"))
        # try to get ref user
        $uRef = $usersRef | Where-Object -Property ObjectGUID -EQ $uIST.ObjectGUID
        # if no ref user found, add event to list
        if (!$uRef){
            $ev = [event]::new()
            $ev.ID = 1
            $ev.SrcUser = $uIST.ObjectGUID
            $ERR_list.Add($ev)
            continue
        }
        # comparisons. if not equal, create event
        if ($uRef.Username -ne $username){
            $ev = [event]::new()
            $ev.ID = 3
            $ev.SrcUser = $uIST.ObjectGUID
            $ev.SrcRefUser = $uRef.ObjectGUID
            $ERR_list.Add($ev)
        }
        if ($uRef.DisplayName -ne $uIST.DisplayName){
            $ev = [event]::new()
            $ev.ID = 4
            $ev.SrcUser = $uIST.ObjectGUID
            $ev.SrcRefUser = $uRef.ObjectGUID
            $ERR_list.Add($ev)
        }
        if ($uRef.Enabled -ne $uIST.Enabled){
            $ev = [event]::new()
            $ev.ID = 5
            $ev.SrcUser = $uIST.ObjectGUID
            $ev.SrcRefUser = $uRef.ObjectGUID
            $ERR_list.Add($ev)
        }
    }

    # add all users that are not in IST
    foreach ($uRef in $usersRefNoGUID){
        $ev = [event]::new()
        $ev.ID = 2
        $ev.SrcRefUser = $uRef.ObjectGUID
        $ERR_list.Add($ev)
    }

    # Do Group Comparison
    foreach($gIST in $groupsIST){
        # try to get ref group
        $gRef = $groupsRef | Where-Object -Property ObjectGUID -EQ $gIST.ObjectGUID
        # if no ref group found, add event to list
        if (!$gRef){
            $ev = [event]::new()
            $ev.ID = 6
            $ev.SrcUser = $gIST.ObjectGUID
            $ERR_list.Add($ev)
            continue
        }
        # comparisons. if not equal, create event
        if ($gRef.CommonName -ne $gIST.CommonName){
            $ev = [event]::new()
            $ev.ID = 8
            $ev.SrcGroup = $gIST.ObjectGUID
            $ev.SrcRefGroup = $gRef.ObjectGUID
            $ERR_list.Add($ev)
        }
        if ($gRef.GroupType -ne $gIST.GroupType){
            $ev = [event]::new()
            $ev.ID = 9
            $ev.SrcGroup = $gIST.ObjectGUID
            $ev.SrcRefGroup = $gRef.ObjectGUID
            $ERR_list.Add($ev)
        }
        if ($gRef.GroupTypeSecurity -ne $gIST.GroupTypeSecurity){
            $ev = [event]::new()
            $ev.ID = 10
            $ev.SrcGroup = $gIST.ObjectGUID
            $ev.SrcRefGroup = $gRef.ObjectGUID
            $ERR_list.Add($ev)
        }

        # add all groups that are not in IST
        foreach ($gRef in $groupsRefNoGUID){
            $ev = [event]::new()
            $ev.ID = 7
            $ev.SrcRefGroup = $gRef.ObjectGUID
            $ERR_list.Add($ev)
        }

        # get users that should be in a group but are not
        foreach ($ugRef in $usergroupsRef){
            $ugIST = $usergroupsIST | Where-Object {$_.UserObjectGUID -eq $ugRef.UserObjectGUID -and $_.GroupObjectGUID -eq $ugRef.GroupObjectGUID}
            if (!$ugIST){
                $ev = [event]::new()
                $ev.ID = 11
                $ev.SrcUser = $ugRef.UserObjectGUID
                $ev.SrcRefUser = $ugRef.UserObjectGUID
                $ev.DstRefGroup = $ugRef.GroupObjectGUID
                $ERR_list.Add($ev)
            }
        }

        # get users that are in group but should not
        foreach ($ugIST in $usergroupsIST){
            $ugRef = $usergroupsRef | Where-Object {$_.UserObjectGUID -eq $ugIST.UserObjectGUID -and $_.GroupObjectGUID -eq $ugIST.GroupObjectGUID}
            if (!$ugRef){
                $ev = [event]::new()
                $ev.ID = 12
                $ev.SrcUser = $ugIST.UserObjectGUID
                $ev.SrcRefUser = $ugIST.UserObjectGUID
                $ev.DstGroup = $ugIST.GroupObjectGUID
                $ERR_list.Add($ev)
            }
        }

        # get groups that should be in a group but are not
        foreach ($ggRef in $groupgroupsRef){
            $ggIST = $groupgroupsIST | Where-Object {$_.ChildGroupObjectGUID -eq $ggRef.ChildGroupObjectGUID -and $_.ParentGroupObjectGUID -eq $ggRef.ParentGroupObjectGUID}
            if (!$ggIST){
                $ev = [event]::new()
                $ev.ID = 13
                $ev.SrcGroup = $ggRef.ChildGroupObjectGUID
                $ev.SrcRefGroup = $ggRef.ChildGroupObjectGUID
                $ev.DstRefGroup = $ggRef.ParentGroupObjectGUID
                $ERR_list.Add($ev)
            }
        }

        # get groups that are in group but should not
        foreach ($ggIST in $groupgroupsIST){
            $ggRef = $groupgroupsRef | Where-Object {$_.ChildGroupObjectGUID -eq $ggIST.ChildGroupObjectGUID -and $_.ParentGroupObjectGUID -eq $ggIST.ParentGroupObjectGUID}
            if (!$ggRef){
                $ev = [event]::new()
                $ev.ID = 14
                $ev.SrcGroup = $ugIST.ChildGroupObjectGUID
                $ev.SrcRefGroup = $ugIST.ChildGroupObjectGUID
                $ev.DstGroup = $ugIST.ParentGroupObjectGUID
                $ERR_list.Add($ev)
            }
        }

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