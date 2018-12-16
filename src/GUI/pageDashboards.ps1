#Dashboard: Department Leader
$pageDBDepLead = New-UDPage -Name "Dashboard DepLead" -AuthorizedRole @("WRADadmin", "DepLead") -AutoRefresh -RefreshInterval 30 -Content {
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #False rights (SollIstVergleich)
            
            #get Data
            $output = get-WRADDBADInconsistence

            #Display data
            New-UDGrid -Title $output[0] -Header $output[1] -Properties $output[2] -Endpoint {
                $output[3] | Out-UDGridData
            } -DefaultSortColumn "Date" -DefaultSortDescending
        }
        New-UDColumn -Size 6 -Content {
            #Last changes (Log)

            #Get Data
            $output = get-WRADDBLastChanges

            #Display Data
            New-UDGrid -Title $output[0] -Header $output[1] -Properties $output[2] -Endpoint {
                $output[3] | Out-UDGridData
            } -DefaultSortColumn "Date" -DefaultSortDescending
        }
    } 
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #Last logon grid
            
            #Get Data
            $output = get-WRADDBUserStatusGrid

            #Display Data
            New-UDGrid -Title $output[0] -Header $output[1] -Properties $output[2] -Endpoint {
                $output[3] | Out-UDGridData
            }
        }
        New-UDColumn -Size 6 -Content {
            #Last logon Chart [%]

            $output = get-WRADDBUserStatusChart

            New-UDChart -Title $output[0] -Type $output[1] -RefreshInterval 5 -Endpoint { 
				$output[5] | Out-UDChartData -LabelProperty $output[2] -Dataset @(
                    New-UDChartDataset -DataProperty $output[3] -Label $output[4] -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr -
                )
			}
        }
    }
}

#Dashboard: Auditor
$pageDBAuditor = New-UDPage -Name "Dashboard Auditor" -AuthorizedRole @("WRADadmin", "Auditor") -AutoRefresh -RefreshInterval 30 -Content {
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #False rights (SollIstVergleich)
            
            #get Data
            $output = get-WRADDBADInconsistence

            #Display data
            New-UDGrid -Title $output[0] -Header $output[1] -Properties $output[2] -Endpoint {
                $output[3] | Out-UDGridData
            } -DefaultSortColumn "Date" -DefaultSortDescending
        }
        New-UDColumn -Size 6 -Content {
            #Last logon Chart [%]

            $output = get-WRADDBUserStatusChart

            New-UDChart -Title $output[0] -Type $output[1] -RefreshInterval 5 -Endpoint { 
				$output[5] | Out-UDChartData -LabelProperty $output[2] -Dataset @(
                    New-UDChartDataset -DataProperty $output[3] -Label $output[4] -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr -
                )
			}
        }
    }
}

#Dashboard: SystemAdmin
$pageDBSysadm = New-UDPage -Name "Dashboard Sysadmin" -AuthorizedRole @("WRADadmin", "SysAdm") -AutoRefresh -RefreshInterval 30 -Content {
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #False rights (SollIstVergleich)
            
            #get Data
            $output = get-WRADDBADInconsistence

            #Display data
            New-UDGrid -Title $output[0] -Header $output[1] -Properties $output[2] -Endpoint {
                $output[3] | Out-UDGridData
            } -DefaultSortColumn "Date" -DefaultSortDescending
        }
        New-UDColumn -Size 6 -Content {
            #Last changes (Log)

            #Get Data
            $output = get-WRADDBLastChanges

            #Display Data
            New-UDGrid -Title $output[0] -Header $output[1] -Properties $output[2] -Endpoint {
                $output[3] | Out-UDGridData
            } -DefaultSortColumn "Date" -DefaultSortDescending
        }
    } 
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #Last logon grid
            
            #Get Data
            $output = get-WRADDBUserStatusGrid

            #Display Data
            New-UDGrid -Title $output[0] -Header $output[1] -Properties $output[2] -Endpoint {
                $output[3] | Out-UDGridData
            }
        }
        New-UDColumn -Size 6 -Content {
            #Last logon Chart [%]

            $output = get-WRADDBUserStatusChart

            New-UDChart -Title $output[0] -Type $output[1] -RefreshInterval 5 -Endpoint { 
				$output[5] | Out-UDChartData -LabelProperty $output[2] -Dataset @(
                    New-UDChartDataset -DataProperty $output[3] -Label $output[4] -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr -
                )
			}
        }
    }
}