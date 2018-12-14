function Get-WRADEventText{
    Param
    (
        [Switch]$html,

        [Parameter(Mandatory=$True)]
		[Object[]]$evs
    )

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

    $event_text_list = New-Object System.Collections.Generic.List[System.Object]
    $events = $evs |Sort-Object EventType

    foreach ($ev in $events){
        $text = ""
        if ($ev.EventType -eq 1){
            $usrIST = Get-WRADUser -ObjectGUID $ev.SrcUserObjectGUID
            $text = "User '$($usrIST.userPrincipalName)' not in SOLL" 
        }
        if ($ev.EventType -eq 2){
            $usrSOLL = Get-WRADUser -Reference -ObjectGUID $ev.SrcRefUserObjectGUID
            $text = "User '$($usrSoll.Username)' not in IST" 
        }
        if ($ev.EventType -eq 3){
            $usrIST = Get-WRADUser -ObjectGUID $ev.SrcUserObjectGUID
            $usrSOLL = Get-WRADUser -Reference -ObjectGUID $ev.SrcRefUserObjectGUID
            $text = "Username wrong: IST: '$($usrIST.userPrincipalName)' != SOLL: '$($usrSOLL.Username)'" 
        }
        if ($ev.EventType -eq 4){
            $usrIST = Get-WRADUser -ObjectGUID $ev.SrcUserObjectGUID
            $usrSOLL = Get-WRADUser -Reference -ObjectGUID $ev.SrcRefUserObjectGUID
            $text = "DisplayName wrong: IST: '$($usrIST.DisplayName)' != SOLL: '$($usrSOLL.DisplayName)'"
        }
        if ($ev.EventType -eq 5){
            $usrIST = Get-WRADUser -ObjectGUID $ev.SrcUserObjectGUID
            $usrSOLL = Get-WRADUser -Reference -ObjectGUID $ev.SrcRefUserObjectGUID
            $text = "Enabled/Disabled: '$($usrIST.userPrincipalName)' IST: '$($usrIST.Enabled)' != SOLL: '$($usrSOLL.Enabled)'"
        }
        if ($ev.EventType -eq 6){
            $grpIST = Get-WRADGroup -ObjectGUID $ev.SrcGroupObjectGUID
            $text = "Group '$($grpIST.CommonName)' not in SOLL"
        }
        if ($ev.EventType -eq 7){
            $grpSOLL = Get-WRADGroup -Reference -ObjectGUID $ev.SrcRefGroupObjectGUID
            $text = "Group '$($grpSOLL.CommonName)' not in IST"
        }
        if ($ev.EventType -eq 8){
            $grpIST = Get-WRADGroup -ObjectGUID $ev.SrcGroupObjectGUID
            $grpSOLL = Get-WRADGroup -Reference -ObjectGUID $ev.SrcRefGroupObjectGUID
            $text = "CommonName wrong: IST: '$($grpIST.CommonName)' != SOLL: '$($grpSOLL.CommonName)'"
        }
        if ($ev.EventType -eq 9){
            $grpIST = Get-WRADGroup -ObjectGUID $ev.SrcGroupObjectGUID
            $grpSOLL = Get-WRADGroup -Reference -ObjectGUID $ev.SrcRefGroupObjectGUID
            $text = "GroupType wrong: '$($grpIST.CommonName)' IST: '$($grpIST.GroupType)' != SOLL: '$($grpSOLL.GroupType)'"
        }
        if ($ev.EventType -eq 10){
            $grpIST = Get-WRADGroup -ObjectGUID $ev.SrcGroupObjectGUID
            $grpSOLL = Get-WRADGroup -Reference -ObjectGUID $ev.SrcRefGroupObjectGUID
            $text = "GroupTypeSecurity wrong: '$($grpIST.CommonName)' IST: '$($grpIST.GroupTypeSecurity)' != SOLL: '$($grpSOLL.GroupTypeSecurity)'"
        }
        if ($ev.EventType -eq 11){
            $usrIST = Get-WRADUser -ObjectGUID $ev.SrcUserObjectGUID
            $grpSOLL = Get-WRADGroup -Reference -ObjectGUID $ev.DestRefGroupObjectGUID
            $text = "User '$($usrIST.userPrincipalName)' should be in group '$($grpSOLL.CommonName)' but is not" 
        }
        if ($ev.EventType -eq 12){
            $usrIST = Get-WRADUser -ObjectGUID $ev.SrcUserObjectGUID
            $grpIST = Get-WRADGroup -ObjectGUID $ev.DestGroupObjectGUID
            $text = "User '$($usrIST.userPrincipalName)' is in group '$($grpIST.CommonName)' but should not" 
        }
        if ($ev.EventType -eq 13){
            $grpIST = Get-WRADGroup -ObjectGUID $ev.SrcGroupObjectGUID
            $grpSOLL = Get-WRADGroup -Reference -ObjectGUID $ev.DestRefGroupObjectGUID
            $text = "Group '$($grpIST.CommonName)' should be in group '$($grpSOLL.CommonName)' but is not" 
        }
        if ($ev.EventType -eq 14){
            $grpIST = Get-WRADGroup -ObjectGUID $ev.SrcGroupObjectGUID
            $grpSOLL = Get-WRADGroup -ObjectGUID $ev.DestGroupObjectGUID
            $text = "User '$($grpIST.CommonName)' is in group '$($grpSOLL.CommonName)' but should not"
        }
        if ($html){
            $text = $text -replace "&", "&amp;"
            $text = $text -replace "ö", "&ouml;"
            $text = $text -replace "Ö", "&Ouml;"
            $text = $text -replace "ä", "&auml;"
            $text = $text -replace "Ä", "&Auml;"
            $text = $text -replace "Ü", "&Uuml;"
            $text = $text -replace "ü", "&uuml;"
            $text = $text -replace "<", "&lt;"
            $text = $text -replace "<", "&gt;"
        }
        $event_text_list.Add($text)
    }
    return $event_text_list

    <#
    .SYNOPSIS

    

    .DESCRIPTION

    

    .INPUTS



    .OUTPUTS

    

    .EXAMPLE

    C:\PS> 
    
    #>
}