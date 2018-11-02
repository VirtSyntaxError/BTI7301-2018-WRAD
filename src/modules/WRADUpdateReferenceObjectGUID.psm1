function Update-WRADReferenceObjectGUID{
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

    # get ref data where noguid (yet)
    $users_ref = Get-WRADUser -Reference -NoObjectGUID
    $groups_ref = Get-WRADGroup -Reference -NoObjectGUID

    # loop through users
    foreach ($u_ref in $users_ref){
        # try to get GUID from IST
        $username = $u_ref.Username
        $old_guid = $u_ref.ObjectGUID
        $new_guid = ""
        $user_ist = Get-WRADUser -UserPrincipalName $username
        # if no user found, leave guid, else update guid
        if ($user_ist){
            $new_guid = $user_ist.ObjectGUID
            # update user guid
            Update-WRADUser -Reference -ObjectGUID $old_guid -NewObjectGUID $new_guid
        }
    }
    # loop through groups
    foreach ($g_ref in $groups_ref){
        # try to get GUID from IST
        $groupname = $g_ref.CommonName
        $old_guid = $g_ref.ObjectGUID
        $new_guid = ""
        $group_ist = Get-WRADGroup -CommonName $groupname
        # if no group found, leave guid, else update guide
        if ($group_ist){
            $new_guid = $group_ist.ObjectGUID
            # update user guide
            Update-WRADGroup -Reference -ObjectGUID $old_guid -NewObjectGUID $new_guid
        }
    }
    
    
    <#
    .SYNOPSIS

    Match the noguid SOLL items to their IST items.

    .DESCRIPTION

    Match the noguid SOLL items to their IST items.

    .INPUTS



    .OUTPUTS

    Changes GUIDs to IST Guid

    .EXAMPLE

    C:\PS> Update-WRADReferenceObjectGUID
    
    #>
}