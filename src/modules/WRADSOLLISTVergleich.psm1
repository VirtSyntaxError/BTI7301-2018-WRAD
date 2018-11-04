class WRADEvent
{
    [int]$EventID
    [String]$SrcUser
    [String]$SrcGroup
    [String]$SrcRefUser
    [String]$SrcRefGroup
    [String]$DestGroup
    [String]$DestRefGroup
    [int]$EventType
}
function Invoke-WRADSOLLISTVergleich{
    # import DB module
    try
	{
		Write-Verbose "Loading PS Module WRADDBCommands and WRADEvent Class"
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

    # define empty error list
    $ERR_list = New-Object System.Collections.Generic.List[System.Object]
    # get old events that are not resolved
    $ERR_old = Get-WRADEvent -NotResolved
    
    # Do User Comparison
    foreach($uIST in $usersIST){
        # get UPN
        $username_upn = $uIST.userPrincipalName
        # get UPN without domain (if contains domain)
        $username = ""
        if ($username.IndexOf("@") -gt 0){
            $username = $username_upn.Substring(0,$username.IndexOf("@"))
        } else {
            $username = $username_upn
        }
        
        # try to get ref user
        $uRef = $usersRef | Where-Object -Property ObjectGUID -EQ $uIST.ObjectGUID
        # if no ref user found, add event to list
        if (!$uRef){
            $ev = [WRADEvent]::new()
            $ev.EventType = 1
            $ev.SrcUser = $uIST.ObjectGUID
            $ERR_list.Add($ev)
            continue
        }
        # comparisons. if not equal, create event
        if ($uRef.Username -ne $username){
            $ev = [WRADEvent]::new()
            $ev.EventType = 3
            $ev.SrcUser = $uIST.ObjectGUID
            $ev.SrcRefUser = $uRef.ObjectGUID
            $ERR_list.Add($ev)
        }
        if ($uRef.DisplayName -ne $uIST.DisplayName){
            $ev = [WRADEvent]::new()
            $ev.EventType = 4
            $ev.SrcUser = $uIST.ObjectGUID
            $ev.SrcRefUser = $uRef.ObjectGUID
            $ERR_list.Add($ev)
        }
        if ($uRef.Enabled -ne $uIST.Enabled){
            $ev = [WRADEvent]::new()
            $ev.EventType = 5
            $ev.SrcUser = $uIST.ObjectGUID
            $ev.SrcRefUser = $uRef.ObjectGUID
            $ERR_list.Add($ev)
        }
    }

    # add all users that are not in IST
    foreach ($uRef in $usersRefNoGUID){
        $ev = [WRADEvent]::new()
        $ev.EventType = 2
        $ev.SrcRefUser = $uRef.ObjectGUID
        $ERR_list.Add($ev)
    }

    # Do Group Comparison
    foreach($gIST in $groupsIST){
        # try to get ref group
        $gRef = $groupsRef | Where-Object -Property ObjectGUID -EQ $gIST.ObjectGUID
        # if no ref group found, add event to list
        if (!$gRef){
            $ev = [WRADEvent]::new()
            $ev.EventType = 6
            $ev.SrcUser = $gIST.ObjectGUID
            $ERR_list.Add($ev)
            continue
        }
        # comparisons. if not equal, create event
        if ($gRef.CommonName -ne $gIST.CommonName){
            $ev = [WRADEvent]::new()
            $ev.EventType = 8
            $ev.SrcGroup = $gIST.ObjectGUID
            $ev.SrcRefGroup = $gRef.ObjectGUID
            $ERR_list.Add($ev)
        }
        if ($gRef.GroupType -ne $gIST.GroupType){
            $ev = [WRADEvent]::new()
            $ev.EventType = 9
            $ev.SrcGroup = $gIST.ObjectGUID
            $ev.SrcRefGroup = $gRef.ObjectGUID
            $ERR_list.Add($ev)
        }
        if ($gRef.GroupTypeSecurity -ne $gIST.GroupTypeSecurity){
            $ev = [WRADEvent]::new()
            $ev.EventType = 10
            $ev.SrcGroup = $gIST.ObjectGUID
            $ev.SrcRefGroup = $gRef.ObjectGUID
            $ERR_list.Add($ev)
        }
    }

    # add all groups that are not in IST
    foreach ($gRef in $groupsRefNoGUID){
        $ev = [WRADEvent]::new()
        $ev.EventType = 7
        $ev.SrcRefGroup = $gRef.ObjectGUID
        $ERR_list.Add($ev)
    }

    # get users that should be in a group but are not
    foreach ($ugRef in $usergroupsRef){
        $ugIST = $usergroupsIST | Where-Object {$_.UserObjectGUID -eq $ugRef.UserObjectGUID -and $_.GroupObjectGUID -eq $ugRef.GroupObjectGUID}
        if (!$ugIST){
            $ev = [WRADEvent]::new()
            $ev.EventType = 11
            $ev.SrcUser = $ugRef.UserObjectGUID
            $ev.SrcRefUser = $ugRef.UserObjectGUID
            $ev.DestRefGroup = $ugRef.GroupObjectGUID
            $ERR_list.Add($ev)
        }
    }

    # get users that are in group but should not
    foreach ($ugIST in $usergroupsIST){
        $ugRef = $usergroupsRef | Where-Object {$_.UserObjectGUID -eq $ugIST.UserObjectGUID -and $_.GroupObjectGUID -eq $ugIST.GroupObjectGUID}
        if (!$ugRef){
            $ev = [WRADEvent]::new()
            $ev.EventType = 12
            $ev.SrcUser = $ugIST.UserObjectGUID
            $ev.SrcRefUser = $ugIST.UserObjectGUID
            $ev.DestGroup = $ugIST.GroupObjectGUID
            $ERR_list.Add($ev)
        }
    }

    # get groups that should be in a group but are not
    foreach ($ggRef in $groupgroupsRef){
        $ggIST = $groupgroupsIST | Where-Object {$_.ChildGroupObjectGUID -eq $ggRef.ChildGroupObjectGUID -and $_.ParentGroupObjectGUID -eq $ggRef.ParentGroupObjectGUID}
        if (!$ggIST){
            $ev = [WRADEvent]::new()
            $ev.EventType = 13
            $ev.SrcGroup = $ggRef.ChildGroupObjectGUID
            $ev.SrcRefGroup = $ggRef.ChildGroupObjectGUID
            $ev.DestRefGroup = $ggRef.ParentGroupObjectGUID
            $ERR_list.Add($ev)
        }
    }

    # get groups that are in group but should not
    foreach ($ggIST in $groupgroupsIST){
        $ggRef = $groupgroupsRef | Where-Object {$_.ChildGroupObjectGUID -eq $ggIST.ChildGroupObjectGUID -and $_.ParentGroupObjectGUID -eq $ggIST.ParentGroupObjectGUID}
        if (!$ggRef){
            $ev = [WRADEvent]::new()
            $ev.EventType = 14
            $ev.SrcGroup = $ugIST.ChildGroupObjectGUID
            $ev.SrcRefGroup = $ugIST.ChildGroupObjectGUID
            $ev.DestGroup = $ugIST.ParentGroupObjectGUID
            $ERR_list.Add($ev)
        }
    }

    # handle events
    foreach ($ev_new in $ERR_list){
        $ev_old = $ERR_old | Where-Object {$_.SrcUserObjectGUID -eq $ev_new.SrcUser -and $_.SrcGroupObjectGUID -eq $ev_new.SrcGroup -and $_.SrcRefUserObjectGUID -eq $ev_new.SrcRefUser -and $_.SrcRefGroupObjectGUID -eq $ev_new.SrcRefGroup -and $_.DestGroupObjectGUID -eq $ev_new.DestGroup -and $_.DestRefGroupObjectGUID -eq $ev_new.DestRefGroup -and $_.EventType -eq $ev_new.EventType}
        if ($ev_old){
            # if the event already exists, remove it from old
            $ERR_old = $ERR_old | Where-Object {$_.EventID -ne $ev_old.EventID}
        } else {
            # else add the event
            New-WRADEvent -SrcUserObjectGUID $ev_new.SrcUser -SrcGroupObjectGUID $ev_new.SrcGroup -SrcRefUserObjectGUID $ev_new.SrcRefUser -SrcRefGroupObjectGUID $ev_new.SrcRefGroup -DestGroupObjectGUID $ev_new.DestGroup -DestRefGroupObjectGUID $ev_new.DestRefGroup -EventType $ev_new.EventType
        }
    }

    # go through left old events and set them resolved
    foreach ($ev_old in $ERR_old){
        Set-WRADEventResolved -EventID $ev_old.EventID
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