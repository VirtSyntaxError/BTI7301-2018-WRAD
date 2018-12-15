$Script:ScriptPath = $PSScriptRoot

#Save Variables for Enpoint-Runspaces
$WRADEndpointVar = New-Object -TypeName psobject 
$WRADEndpointVar | Add-Member -MemberType NoteProperty -Name dbconnection -Value $Global:WRADDBConnection
$WRADEndpointVar | Add-Member -MemberType NoteProperty -Name scrptroot -Value $PSScriptRoot

function load-WRADUDDashboard {
    Param()
    try{
        if(!(get-module UniversalDashboard)){
	        Import-Module UniversalDashboard
            write-host "Import Module UniversalDasboard"
        }
    } 
    catch {
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load UD."
    }
}

function load-WRADModules {
    Param()
    try {
        #load WRADDBCommands
        if(!(get-module WRADDBCommands)){
            Import-Module $Script:ScriptPath\..\modules\WRADDBCommands.psm1
            write-host "Import Module WRADCommands"
        }
        #load WRADEventText
        if(!(get-module WRADEventText)){
            Import-Module $Script:ScriptPath\..\modules\WRADEventText.psm1
            write-host "Import Module WRADCommands"
        }
        #load WRADLogging
        if(!(get-module WRADLogging)){
            Import-Module $Script:ScriptPath\..\modules\WRADLogging.psm1
            write-host "Import Module WRADCommands"
        }
    }
    catch {
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load WRAD DB Commands. $($_.Exception.Message)"
    }
}

function enable-WRADLogging {
    Param()
    try {
        $date = Get-Date -UFormat "%Y%m%d"
        Enable-UDLogging -FilePath "C:\Data\Logs\UDLog_$date.txt" -Level Warning
    }
    catch {
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load UD Logging."
    }
}

function reload-WRADGUIContent {
    Param()
    try {
        $AllUser = Get-WRADUser -Reference
        $AllGroups = Get-WRADGroup -Reference
    }
    catch {
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load UD Logging."
    }
}

load-WRADUDDashboard
enable-WRADLogging
load-WRADModules

$InitiateWRADEndpoint = New-UDEndpointInitialization -Module $PSScriptRoot\..\modules\WRADDBCommands.psm1 -Function enable-WRADLogging,load-WRADModules #-Variable $ScrptRt 

#----------------------------------------------------------------------------------------------------------------------------------------------------------------


#Login
$auth = New-UDAuthenticationMethod -Endpoint {
	param([PSCredential]$Credentials)

	#Import-Module ADAuth

	$AuthorizedGroup = 'Administrators'

	#if ($Credentials | ? {$_ | Test-ADCredential} | Test-ADGroupMembership -TargetGroup $AuthorizedGroup) {
	#	New-UDAuthenticationResult -Success -UserName $Credentials.UserName -Role "WRADadmin"
	#} else

    if ($Credentials.UserName -eq "Auditor" -and $Credentials.GetNetworkCredential().Password -eq "Auditor") {
		New-UDAuthenticationResult -Success -UserName $Credentials.UserName -Role "Auditor"
    } ElseIf ($Credentials.UserName -eq "Admin" -and $Credentials.GetNetworkCredential().Password -eq "Admin") {
		New-UDAuthenticationResult -Success -UserName $Credentials.UserName -Role "WRADadmin"
    }

	New-UDAuthenticationResult -ErrorMessage "You are not allowed to login!"
}
    
$login = new-UDLoginPage -AuthenticationMethod $auth -WelcomeText "Welcome to WRAD" -PageBackgroundColor "white" -LoginFormFontColor "black" -LoginFormBackgroundColor "grey"
#---------------------------------------------------------------------------------------------------------------
#Load outsourced Pages
. .\pageSettings.ps1
. .\pageAddUserAndGroup.ps1
. .\pageEditUser.ps1
. .\pageEditGroup.ps1
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Close runnig Dashboards
Get-UDDashboard | Stop-UDDashboard

#Themes Azure,Blue,Default,Earth,Green,Red
$theme = Get-UDTheme -Name "Azure"

#Start Dashboard
Start-UDDashboard -Port 10000 -AllowHttpForLogin -Content {
    
    New-UDDashboard -Login $login -Pages @($PageSettings, $PageAddUser, $PageEditUser, $PageEditUserDyn, $PageEditGroup, $PageEditGroupDyn) -Title "Project WRAD" -Color 'Black' -Theme $theme -EndpointInitialization $InitiateWRADEndpoint
    
}
#-Verbose -debug