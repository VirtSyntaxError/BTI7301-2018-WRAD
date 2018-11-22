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
            $text = "User '$($ev.SrcUserObjectGUID)' not in SOLL" 
        }
        if ($ev.EventType -eq 2){
            $text = "User '$($ev.SrcRefUserObjectGUID)' not in IST" 
        }
        if ($ev.EventType -eq 3){
            $usrIST = Get-WRADUser -ObjectGUID $ev.SrcUserObjectGUID
            $usrSOLL = Get-WRADUser -Reference -ObjectGUID $ev.SrcRefUserObjectGUID
            $text = "Username wrong: '$($ev.SrcUserObjectGUID)' -> '$($usrIST.userPrincipalName)' != '$($usrSOLL.Username)'" 
        }
        if ($ev.EventType -eq 4){
            $usrIST = Get-WRADUser -ObjectGUID $ev.SrcUserObjectGUID
            $usrSOLL = Get-WRADUser -Reference -ObjectGUID $ev.SrcRefUserObjectGUID
            $text = "DisplayName wrong: '$($ev.SrcUserObjectGUID)' -> '$($usrIST.DisplayName)' != '$($usrSOLL.DisplayName)'"
        }
        if ($ev.EventType -eq 5){
            $usrIST = Get-WRADUser -ObjectGUID $ev.SrcUserObjectGUID
            $usrSOLL = Get-WRADUser -Reference -ObjectGUID $ev.SrcRefUserObjectGUID
            $text = "Enabled/Disabled: '$($ev.SrcUserObjectGUID)' -> '$($usrIST.Enabled)' != '$($usrSOLL.Enabled)'"
        }
        if ($ev.EventType -eq 6){
            $text = "Group '$($ev.SrcGroupObjectGUID)' not in SOLL"
        }
        if ($ev.EventType -eq 7){
            $text = "Group '$($ev.SrcRefGroupObjectGUID)' not in IST"
        }
        if ($ev.EventType -eq 8){
            $grpIST = Get-WRADGroup -ObjectGUID $ev.SrcGroupObjectGUID
            $grpSOLL = Get-WRADGroup -Reference -ObjectGUID $ev.SrcRefGroupObjectGUID
            $text = "CommonName wrong: '$($ev.SrcGroupObjectGUID)' -> '$($grpIST.CommonName)' != '$($grpSOLL.CommonName)'"
        }
        if ($ev.EventType -eq 9){
            $grpIST = Get-WRADGroup -ObjectGUID $ev.SrcGroupObjectGUID
            $grpSOLL = Get-WRADGroup -Reference -ObjectGUID $ev.SrcRefGroupObjectGUID
            $text = "GroupType wrong: '$($ev.SrcGroupObjectGUID)' -> '$($grpIST.GroupType)' != '$($grpSOLL.GroupType)'"
        }
        if ($ev.EventType -eq 10){
            $grpIST = Get-WRADGroup -ObjectGUID $ev.SrcGroupObjectGUID
            $grpSOLL = Get-WRADGroup -Reference -ObjectGUID $ev.SrcRefGroupObjectGUID
            $text = "GroupTypeSecurity wrong: '$($ev.SrcGroupObjectGUID)' -> '$($grpIST.GroupTypeSecurity)' != '$($grpSOLL.GroupTypeSecurity)'"
        }
        if ($ev.EventType -eq 11){
            $text = "User '$($ev.SrcUserObjectGUID)' should be in group '$($ev.DestRefGroupObjectGUID)' but is not" 
        }
        if ($ev.EventType -eq 12){
            $text = "User '$($ev.SrcUserObjectGUID)' is in group '$($ev.DestGroupObjectGUID)' but should not" 
        }
        if ($ev.EventType -eq 13){
            $text = "Group '$($ev.SrcGroupObjectGUID)' should be in group '$($ev.DestRefGroupObjectGUID)' but is not" 
        }
        if ($ev.EventType -eq 14){
            $text = "User '$($ev.SrcGroupObjectGUID)' is in group '$($ev.DestGroupObjectGUID)' but should not"
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