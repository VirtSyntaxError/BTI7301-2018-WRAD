#Dashboard: Department Leader
$pageDBDepLead = New-UDPage -Name "Dashboard DepLead" -AuthorizedRole @("WRADadmin", "DepLead") -AutoRefresh -RefreshInterval 30 -Content {
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #False rights (SollIstVergleich)

            #Show Grid
            New-UDGrid -Title "AD Inconsistency" -Header @("Text", "Date") -Properties @("Text", "Date") -Endpoint {
                $Script:Scriptpath = $ArgumentList[0].scrptroot

                load-WRADModules

                #get Data
                $output = get-WRADDBADInconsistence

                #Display Data
                $output | Out-UDGridData
            } -ArgumentList $WRADEndpointVar -DefaultSortColumn "Date" -DefaultSortDescending
        }
        New-UDColumn -Size 6 -Content {
            #Last changes (Log)

            #Display Data
            New-UDGrid -Title "Last changes" -Header @("Date", "Severity", "Text") -Properties @("Date", "Severity", "Text") -Endpoint {
                $Script:Scriptpath = $ArgumentList[0].scrptroot

                #Get Data
                $output = get-WRADDBLastChanges
                $output | Out-UDGridData
            } -ArgumentList $WRADEndpointVar -DefaultSortColumn "Date" -DefaultSortDescending
        }
    } 
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #Last logon grid
            
            #Display Data
            New-UDGrid -Title "Last logon" -Header @("Description", "Count") -Properties @("descr", "count") -Endpoint {
                $Script:Scriptpath = $ArgumentList[0].scrptroot

                load-WRADModules

                #Get Data
                $output = get-WRADDBUserStatusGrid
                
                #Dsiplay Data
                $output | Out-UDGridData
            } -ArgumentList $WRADEndpointVar
        }
        New-UDColumn -Size 6 -Content {
            #Last logon Chart [%]

            New-UDChart -Title "Last logon chart [%]" -Type bar -RefreshInterval 5 -Endpoint { 
                $Script:Scriptpath = $ArgumentList[0].scrptroot
                load-WRADModules

                #Get Data
                $output = get-WRADDBUserStatusChart

                #Dsiplay Data
				$output | Out-UDChartData -LabelProperty "descr" -Dataset @(
                    New-UDChartDataset -DataProperty "prcnt" -Label "Users [%]" -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr -
                )
			} -ArgumentList $WRADEndpointVar
        }
    }
}

#Dashboard: Auditor
$pageDBAuditor = New-UDPage -Name "Dashboard Auditor" -AuthorizedRole @("WRADadmin", "Auditor") -AutoRefresh -RefreshInterval 30 -Content {
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #False rights (SollIstVergleich)

            #Show Grid
            New-UDGrid -Title "AD Inconsistency" -Header @("Text", "Date") -Properties @("Text", "Date") -Endpoint {
                $Script:Scriptpath = $ArgumentList[0].scrptroot

                load-WRADModules

                #get Data
                $output = get-WRADDBADInconsistence

                #Display Data
                $output | Out-UDGridData
            } -ArgumentList $WRADEndpointVar -DefaultSortColumn "Date" -DefaultSortDescending
        }
        New-UDColumn -Size 6 -Content {
            #Last logon Chart [%]

            New-UDChart -Title "Last logon chart [%]" -Type bar -RefreshInterval 5 -Endpoint { 
                $Script:Scriptpath = $ArgumentList[0].scrptroot
                load-WRADModules

                #Get Data
                $output = get-WRADDBUserStatusChart

                #Dsiplay Data
				$output | Out-UDChartData -LabelProperty "descr" -Dataset @(
                    New-UDChartDataset -DataProperty "prcnt" -Label "Users [%]" -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr -
                )
			} -ArgumentList $WRADEndpointVar
        }
    }
}

#Dashboard: SystemAdmin
$pageDBSysadm = New-UDPage -Name "Dashboard Sysadmin" -AuthorizedRole @("WRADadmin", "SysAdm") -AutoRefresh -RefreshInterval 30 -Content {
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #False rights (SollIstVergleich)

            #Show Grid
            New-UDGrid -Title "AD Inconsistency" -Header @("Text", "Date") -Properties @("Text", "Date") -Endpoint {
                $Script:Scriptpath = $ArgumentList[0].scrptroot

                load-WRADModules

                #get Data
                $output = get-WRADDBADInconsistence

                #Display Data
                $output | Out-UDGridData
            } -ArgumentList $WRADEndpointVar -DefaultSortColumn "Date" -DefaultSortDescending
        }
        New-UDColumn -Size 6 -Content {
            #Last changes (Log)

            #Display Data
            New-UDGrid -Title "Last changes" -Header @("Date", "Severity", "Text") -Properties @("Date", "Severity", "Text") -Endpoint {
                $Script:Scriptpath = $ArgumentList[0].scrptroot

                #Get Data
                $output = get-WRADDBLastChanges
                $output | Out-UDGridData
            } -ArgumentList $WRADEndpointVar -DefaultSortColumn "Date" -DefaultSortDescending
        }
    } 
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #Last logon grid
            
            #Display Data
            New-UDGrid -Title "Last logon" -Header @("Description", "Count") -Properties @("descr", "count") -Endpoint {
                $Script:Scriptpath = $ArgumentList[0].scrptroot

                load-WRADModules

                #Get Data
                $output = get-WRADDBUserStatusGrid

                $output | Out-UDGridData
            } -ArgumentList $WRADEndpointVar
        }
        New-UDColumn -Size 6 -Content {
            #Last logon Chart [%]

            New-UDChart -Title "Last logon chart [%]" -Type bar -RefreshInterval 5 -Endpoint { 
                $Script:Scriptpath = $ArgumentList[0].scrptroot
                load-WRADModules

                #Get Data
                $output = get-WRADDBUserStatusChart

                #Dsiplay Data
				$output | Out-UDChartData -LabelProperty "descr" -Dataset @(
                    New-UDChartDataset -DataProperty "prcnt" -Label "Users [%]" -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr -
                )
			} -ArgumentList $WRADEndpointVar
        }
    }
}