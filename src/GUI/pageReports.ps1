#Page: Reports
$PageReports = New-UDPage -Name "Action and Reports" -AuthorizedRole @("WRADadmin","Auditor", "DepLead", "SysAdm") -AutoRefresh -RefreshInterval 30 -Content {
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            #Show Reports
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

$PageAaRActions = New-UDPage -Id "PageAaRActions" -URL "/AaR/:action" -ArgumentList $WRADEndpointVar -AuthorizedRole @("WRADadmin","Auditor", "DepLead", "SysAdm") -Endpoint {
	param($action)
    
    $Script:Scriptpath = $ArgumentList[0].scrptroot
    load-WRADModules

    $report = $false
    if($action  -eq "UsrRprt") {
        #Action: Create User Report
        $title = "User report"
        $text = "The user report has been created. Click the link to open: "

        #Start Task and wait until it is finished
        Start-ScheduledTask -TaskName "WRADUsersReport"
        while((Get-ScheduledTask -TaskName "WRADUsersReport").State -ne "Ready"){
            Start-Sleep -Seconds 3
        }

        $report = $true

    } elseif ($action  -eq "EvntRprt") {
        #Action: Create Event Report
        $title = "Event report"
        $text = "The user report has been created. Click the link to open: "
        
        #Start Task and wait until it is finished
        Start-ScheduledTask -TaskName "WRADEventsReport"
        while((Get-ScheduledTask -TaskName "WRADEventsReport").State -ne "Ready"){
            Start-Sleep -Seconds 3
        }

        $report = $true

    } elseif ($action  -eq "BothRprt") {
        #Action: Create Full Report
        $title = "Event and User report"
        $text = "The user report has been created. Click the link to open: "
        
        #Start Task and wait until it is finished
        Start-ScheduledTask -TaskName "WRADFullReport"
        while((Get-ScheduledTask -TaskName "WRADFullReport").State -ne "Ready"){
            Start-Sleep -Seconds 3
        }

        $report = $true

    } elseif ($action  -eq "SIVrgl") {
        #Action: Run should/be comparison
        $title = "Soll- / Ist-Vergleich"
        $text = "The comparison run successfully."

        Start-ScheduledTask -TaskName "WRADGetISTAndCompare"

        while((Get-ScheduledTask -TaskName "WRADGetISTAndCompare").State -ne "Ready"){
            Start-Sleep -Seconds 5
        }

    } elseif ($action  -eq "UsrImport") {
        #Action: Import USer CSV
        $folder = Convert-Path "$Script:Scriptpath\..\csv\"
        $file = "UsrImport.csv"

        $title = "User import"
        $text = "If your file was at $folder$file, then the import has been succefull."
    } elseif ($action  -eq "GrpImport") {
        #Action: Import Group CSV
        $folder = Convert-Path "$Script:Scriptpath\..\csv\"
        $file = "GrpImport.csv"

        $title = "Group import"
        $text = "If your file was at $folder$file, then the import has been succefull."
    } elseif ($action  -eq "UsrExport") {
        #Action: Export USer CSV
        $folder = Convert-Path "$Script:Scriptpath\..\csv\"
        $file = "UsrExport.csv"
        
        #Export-WRADcsv -csvPath $folder$file -ExportOf Users

        $title = "User export"
        $text = "Your file is located at $folder$file."
    } elseif ($action  -eq "GrpExport") {
        #Action: Export Group CSV
        $folder = Convert-Path "$Script:Scriptpath\..\csv\"
        $file = "GrpExport.csv"

        #Export-WRADcsv -csvPath $folder$file -ExportOf Groups

        $title = "Group export"
        $text = "Your file is located at $folder$file."
    } else {
        #Nothing selected
        $title = "Default title"
        $text = "Default"
    }

    #Link to report
    if($report) {
    $path = Convert-Path "$Script:Scriptpath\..\modules\Report.pdf"
        $linktoReport =  New-UDElement -Tag "a" -Attributes @{
            target = "_self"
            href = "#"
            onClick = {
                Start-Process ((Resolve-Path $path).Path)
            }
        } -Content {"Report"}
    } else {
        $linktoReport = ""
    }

    #Display data
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            New-UDCard -Title $title -Content {
                $text
                $linktoReport
            } -Links @(
                New-UDLink -Text 'Back' -Url '../Action-and-Reports'
            )
        }
    }

}