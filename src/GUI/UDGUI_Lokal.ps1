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
            write-host "Import Module WRADCreateReport"
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
    #Return data for false rights and links of user and groups
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

        $title = "AD Inconsistency"
        $header = @("Text", "Date")
        $prprts = @("Text", "Date")

        return($title, $header, $prprts, $opText)

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
        $title = "Last changes"
        $header = @("Date", "Severity", "Text")
        $prprts =  @("Date", "Severity", "Text")
        
        return($title, $header, $prprts, $entries)
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
        $title = "Last logon"
        $header = @("Description", "Count")
        $prprts =  @("descr", "count")
        
        return($title, $header, $prprts, $usrStatus)
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
        $title = "Last logon chart [%]"
        $type = "bar"
        $lblPrprt = "descr"
        $dataPrprt = "prcnt"
        $lbl = "Users [%]"
        
        return($title, $type, $lblPrprt, $dataPrprt, $lbl, $usrStatus)
    }
    catch{
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load UD DB User Status Chart: $($_.Exception.Message)"
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
. .\pageDashboards.ps1
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Page: Reports
$PageReports = New-UDPage -Name "Action and Reports" -AuthorizedRole @("WRADadmin","Auditor", "DepLead", "SysAdmin") -AutoRefresh -RefreshInterval 30 -Content {
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            #Show Reports
            <#$RepUsrActn = New-UDElement -Tag "a" -Attributes @{
                className = "btn"
                target = "_self"
                href = "#"
                onClick = {
                    <#Remove selected Group from Group
                    if([string]::IsNullOrEmpty($Global:WRADDBConnection)){
                        $Global:WRADDBConnection = $DBConnect
                    }

                    #Remove-WRADGroupOfGroup -Reference -ChildGroupObjectGUID $grpguid -ParentGroupObjectGUID $tg.ObjectGUID
                    #Write-WRADLog -logtext "Created User Report" -level 0

                    
<#17:31:44 DashboardHub Endpoint 9b5a0558-23b6-4bdd-8eaf-019c9efce7f5onClick not found.
17:31:44 DashboardHub Failed to execute endpoint. Endpoint 9b5a0558-23b6-4bdd-8eaf-019c9efce7f5onClick not found.
17:31:44 Microsoft.AspNetCore.SignalR.Internal.DefaultHubDispatcher Failed to invoke hub method 'clientEvent'.

                } 
            } -Content {"Create"}#>
            
            $Reports = @()
            $Reports += @{Label = "User Report"; Action = (New-UDLink -Text "Create" -Url "AaR/UsrRprt")}
            $Reports += @{Label = "Event Report"; Action = (New-UDLink -Text "Create" -Url "AaR/EvntRprt")}
            $Reports += @{Label = "Both Reports"; Action = (New-UDLink -Text "Create" -Url "AaR/BothRprt")}
            $Reports += @{Label = "Soll/Ist Vergleich"; Action = (New-UDLink -Text "Run" -Url "AaR/SIVrgl")}
            $Reports += @{Label = "User-CSV"; Action = (New-UDLink -Text "Import" -Url "AaR/UsrImport")}
            $Reports += @{Label = "Group-CSV"; Action = (New-UDLink -Text "Import" -Url "AaR/GrpImport")}
            $Reports += @{Label = "User-CSV"; Action = (New-UDLink -Text "Export" -Url "AaR/UsrExport")}
            $Reports += @{Label = "Group-CSV"; Action = (New-UDLink -Text "Export" -Url "AaR/GrpExport")}

            New-UDGrid -Title "Reports" -Header @("Action", "Edit") -Properties @("Label", "Action") -Endpoint {
                $Reports | Out-UDGridData
            } -DefaultSortColumn "Edit"
        }
    }
}

$PageAaRActions = New-UDPage -Id "PageAaRActions" -URL "/AaR/:action" -ArgumentList $WRADEndpointVar -AuthorizedRole @("WRADadmin","Auditor", "DepLead", "SysAdmin") -Endpoint {
	param($action)
    
    $Global:WRADDBConnection = $ArgumentList[0].dbconnection
    $DBConnect = $Global:WRADDBConnection
    $Script:Scriptpath = $ArgumentList[0].scrptroot

    load-WRADModules



    if($action  -eq "UsrRprt") {
        #$report = Write-WRADReport -users
        #$zippath = $report[$report.Count-1]

        $title = "User report"
        $text = "The user report is saved in the following folder: "


    } elseif ($action  -eq "EvntRprt") {
        $title = "Event report"
        $text = "The event report is saved in the following folder: "
    } elseif ($action  -eq "BothRprt") {
        $title = "Event and User report"
        $text = "Both reports are saved in the following folder: "
    } elseif ($action  -eq "SIVrgl") {
        $title = "Soll- / Ist-Vergleich"
        $text = "The comparison run successfully."
    } elseif ($action  -eq "UsrImport") {
        $folder = Convert-Path "$Script:Scriptpath\..\csv\"
        $file = "UsrImport.csv"

        $title = "User import"
        $text = "If your file was at $folder$file, then the import was succefull."
    } elseif ($action  -eq "GrpImport") {
        $folder = Convert-Path "$Script:Scriptpath\..\csv\"
        $file = "GrpImport.csv"

        $title = "Group import"
        $text = "If your file was at $folder$file, then the import was succefull."
    } elseif ($action  -eq "UsrExport") {
        $folder = Convert-Path "$Script:Scriptpath\..\csv\"
        $file = "UsrExport.csv"
        
        #Export-WRADcsv -csvPath $folder$file -ExportOf Users

        $title = "User export"
        $text = "Your file is located at $folder$file."
    } elseif ($action  -eq "GrpExport") {
        $folder = Convert-Path "$Script:Scriptpath\..\csv\"
        $file = "GrpExport.csv"

        #Export-WRADcsv -csvPath $folder$file -ExportOf Groups

        $title = "Group export"
        $text = "Your file is located at $folder$file."
    } else {
        $title = "Default title"
        $text = "Default"
    }

    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            New-UDCard -Title $title -Content {
                New-UDParagraph -Text $text
            } -Links @(
                New-UDLink -Text 'Back' -Url '../Action-and-Reports'
            )
        }
    }

}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Close runnig Dashboards
Get-UDDashboard | Stop-UDDashboard

#Themes Azure,Blue,Default,Earth,Green,Red
$theme = Get-UDTheme -Name "Azure"
#Publish Folder for Reports
$reportFolder = Publish-UDFolder -Path $PSScriptRoot\..\reports\ -RequestPath "/Reports"

#Start Dashboard
Start-UDDashboard -Port 10000 -AllowHttpForLogin -Content {
    
    New-UDDashboard -Login $login -Pages @($pageDBSysadm, $pageDBDepLead, $pageDBAuditor, $PageAddUser, $PageEditUser, $PageEditUserDyn, $PageEditGroup, $PageEditGroupDyn, $PageReports, $PageAaRActions, $PageSettings) -Title "Project WRAD" -Color 'Black' -Theme $theme -EndpointInitialization $InitiateWRADEndpoint 
    
} -PublishedFolder $reportFolder