$Script:ScriptPath = $PSScriptRoot
#Backgorund for Charts
$FpMBckgrn = "#95cc0000"
$FpMBckgrnHvr = "#A1220C"

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
        #load WRADCreateReport
        if(!(get-module WRADCreateReport)){
            Import-Module $Script:ScriptPath\..\modules\WRADCreateReport.psm1
            write-host "Import Module WRADCreateReport"
        }
        #load WRADcsvSOLL
        if(!(get-module WRADcsvSOLL)){
            Import-Module $Script:ScriptPath\..\modules\WRADcsvSOLL.psm1
            write-host "Import Module WRADcsvSOLL"
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
        Write-Host "Enabled UDLogging"
        Write-UDLog -Level Warning -Message "Could not load UD Logging."
    }
}

#Dashboard Functions
function get-WRADDBADInconsistence {
    #Get WRAD DashBoard: ActiveDirectory Inconsistence
    #Return data for inconsitent rights and links of user and groups
    Param()
    try {
        #get Event Texts
        $events = Get-WRADEvent -NotResolved

        #Prepare DisplayData
        $opText = @()
        ForEach($event in $events){
            $eventText = Get-WRADEventText -evs $event
            $opText += @{Text = $eventText; Date = $event.CreatedDate}
        }

        return($opText)

    }
    catch {
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load UD DB AD Inconsistency: $($_.Exception.Message)"
    }
}

function get-WRADDBLastChanges {
    #Get WRAD DashBoard: Last Changes
    #Return data from Log to display last changes
    Param()
    try{
        #Get Log (Last 10 Chnages)
        $log = Get-WRADLog -Last 20
        
        #Prepare output data
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

        #Return values
        return($entries)
    }
    catch {
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load UD DB Last changes: $($_.Exception.Message)"
    }
}

function get-WRADDBUserStatusGrid {
    Param()
    try{
        #get Report
        $usr = Get-WRADReportUsers

        $disabled = $usr[0]
        $users_30_90 = $usr[1]
        $users_90_X = $usr[2]
        $users_never = $usr[3]
        $chart = $usr[4]
        $allUsrCount = $disabled.Count + $users_30_90.Count + $users_90_X.Count + $users_never.Count
        $allGrpCnt = (Get-WRADGroup -Reference).Count

        #Prepare output data
        $usrStatus = @()
        $usrStatus += @{descr = "Disabled User"; count = $disabled.Count}
        $usrStatus += @{descr = "Last logon between 30 and 90 days"; count = $users_30_90.Count}
        $usrStatus += @{descr = "Last logon older than 90 days"; count = $users_90_X.Count}
        $usrStatus += @{descr = "Never loged in"; count = $users_never.Count}
        $usrStatus += @{descr = "Total Users"; count = $allUsrCount}
        $usrStatus += @{descr = "Total Groups"; count = $allGrpCnt}
                
        #Return vlaues        
        return($usrStatus)
    }
    catch{
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load UD DB User Status Grid: $($_.Exception.Message)"
    }
    
}

function get-WRADDBUserStatusChart {
    Param()
    try{
        #get Report
        $usr = Get-WRADReportUsers

        $disabled = $usr[0]
        $users_30_90 = $usr[1]
        $users_90_X = $usr[2]
        $users_never = $usr[3]
        $chart = $usr[4]
        $allUsrCount = $disabled.Count + $users_30_90.Count + $users_90_X.Count + $users_never.Count

        #Prepare output data
        $usrStatus = @()
        $usrStatus += @{descr = "Disabled User"; prcnt = ($disabled.Count/$allUsrCount)*100}
        $usrStatus += @{descr = "Last logon between 30 and 90 days"; prcnt = ($users_30_90.Count/$allUsrCount)*100}
        $usrStatus += @{descr = "Last logon older than 90 days"; prcnt = ($users_90_X.Count/$allUsrCount)*100}
        $usrStatus += @{descr = "Never loged in"; prcnt = ($users_never.Count/$allUsrCount)*100}
                
        #Return vlaues
        
        return($usrStatus)
    }
    catch{
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load UD DB User Status Chart: $($_.Exception.Message)"
    }
}

load-WRADUDDashboard
enable-WRADLogging
load-WRADModules

$InitiateWRADEndpoint = New-UDEndpointInitialization -Module $PSScriptRoot\..\modules\WRADDBCommands.psm1 -Function enable-WRADLogging,load-WRADModules,get-WRADDBLastChanges,get-WRADDBADInconsistence,get-WRADDBUserStatusGrid,get-WRADDBUserStatusChart #-Variable $ScrptRt 

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
    } ElseIf ($Credentials.UserName -eq "DepLead" -and $Credentials.GetNetworkCredential().Password -eq "DepLead") {
		New-UDAuthenticationResult -Success -UserName $Credentials.UserName -Role "DepLead"
    } ElseIf ($Credentials.UserName -eq "SysAdm" -and $Credentials.GetNetworkCredential().Password -eq "SysAdm") {
		New-UDAuthenticationResult -Success -UserName $Credentials.UserName -Role "SysAdm"
    }

	New-UDAuthenticationResult -ErrorMessage "You are not allowed to login!"
}
    
$login = new-UDLoginPage -AuthenticationMethod $auth -WelcomeText "Welcome to WRAD" -PageBackgroundColor "white" -LoginFormFontColor "black" -LoginFormBackgroundColor "grey"

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Load outsourced Pages
. $PSScriptRoot\pageSettings.ps1
. $PSScriptRoot\pageAddUserAndGroup.ps1
. $PSScriptRoot\pageEditUser.ps1
. $PSScriptRoot\pageEditGroup.ps1
. $PSScriptRoot\pageDashboards.ps1
. $PSScriptRoot\pageReports.ps1
. $PSScriptRoot\pageUserHistory.ps1
. $PSScriptRoot\pageGroupHistory.ps1

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Close runnig Dashboards
Get-UDDashboard | Stop-UDDashboard

#Themes Azure,Blue,Default,Earth,Green,Red
$theme = Get-UDTheme -Name "Azure"

#Start Dashboard
Start-UDDashboard -Port 10000 -AllowHttpForLogin -Content {
    
New-UDDashboard -Login $login -Pages @($pageDBSysadm, 
    $pageDBDepLead, 
    $pageDBAuditor, 
    $PageAddUser, 
    $PageEditUser, 
    $PageEditUserDyn, 
    $PageEditGroup, 
    $PageEditGroupDyn, 
    $PageUserHistory, 
    $PageUserHistoryDetail, 
    $PageGroupHistory, 
    $PageGroupHistoryDetail, 
    $PageReports, 
    $PageAaRActions, 
    $PageSettings) -Title "Project WRAD" -Color 'Black' -Theme $theme -EndpointInitialization $InitiateWRADEndpoint 

}