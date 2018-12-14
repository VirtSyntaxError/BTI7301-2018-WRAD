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
            write-host "Import Module WRADEventText"
        }
        #load WRADLogging
        if(!(get-module WRADLogging)){
            Import-Module $Script:ScriptPath\..\modules\WRADLogging.psm1
            write-host "Import Module WRADLogging"
        }
    }
    catch {
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load WRAD Modules. $($_.Exception.Message)"
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
#Dashboard Auditor/Abteilungsleiter
$pageDBAuditorDepLead = New-UDPage -Name "Dashboard" -AuthorizedRole @("WRADadmin","Auditor", "DepLead") -AutoRefresh -RefreshInterval 30 -Content {
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #False rights (SollIstVergleich)
            
            #get Event Texts
            $events = Get-WRADEvent -NotResolved

            #Prepare DisplayData
            $opText = @()
            ForEach($event in $events){
                $eventText = Get-WRADEventText -evs $event
                $opText += @{Text = $eventText; Date = $event.CreatedDate}
            }

            New-UDGrid -Title "False rights" -Header @("Text", "Date") -Properties @("Text", "Date") -Endpoint {
                $opText | Out-UDGridData
            }
            
        }
        New-UDColumn -Size 6 -Content {
            #Last changes (Log)

            #Get LOg
            $log = Get-WRADLog

            $entries = @()
            ForEach($entry in  $log){
                if($entry.LogSeverity -eq 2){
                    $severity = "Error"
                } elseif ($entry.LogSeverity -eq 1){
                    $severity = "Warning"
                } elseif ($entry.LogSeverity -eq 0){
                    $severity = "Information"
                } else {
                    $severity = "Uknown Severity"
                }

                $entries += @{Date = $entry.LogTimestamp; Severity = $severity; Text = $entry.LogText}
            }

            New-UDGrid -Title "Last changes" -Header @("Date", "Severity", "Text") -Properties @("Date", "Severity", "Text") -Endpoint {
                $entries | Out-UDGridData
            }
        }
    } 
    New-UDRow {
        New-UDColumn -Size 6 -Content {

        }
        New-UDColumn -Size 6 -Content {

        }
    } 
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Close runnig Dashboards
Get-UDDashboard | Stop-UDDashboard

#Themes Azure,Blue,Default,Earth,Green,Red
$theme = Get-UDTheme -Name "Azure"

#Start Dashboard
Start-UDDashboard -Port 10000 -AllowHttpForLogin -Content {
    
    New-UDDashboard -Login $login -Pages @($pageDBAuditorDepLead, $PageSettings, $PageAddUser, $PageEditUser, $PageEditUserDyn, $PageEditGroup, $PageEditGroupDyn) -Title "Project WRAD" -Color 'Black' -Theme $theme -EndpointInitialization $InitiateWRADEndpoint
    
}
#-Verbose -debug