if(!(get-module UniversalDashboard)){
	Import-Module UniversalDashboard
}
$SearchBase = (Get-ADDomain).DistinguishedName


# Dashboard Daten

$FpMBckgrn = "#95cc0000"
$FpMBckgrnHvr = "#A1220C"

$ArrAL_RF = @(
	New-Object PSObject	-Property @{step="Warnung"; date="2018-01-01"; descr="User1 ist in Gruppe2."}
	New-Object PSObject	-Property @{step="Warnung"; date="2018-01-01"; descr="User1 ist in nicht Gruppe1."}
	New-Object PSObject	-Property @{step="Information"; date="2018-01-02"; descr="User2 ist nicht in der AD vorhanden."}
)

$ArrAL_LC = @(
	New-Object PSObject	-Property @{step="Warnung"; date="2018-01-01"; descr="User1 aus Gruppe 1 entfernt."}
	New-Object PSObject	-Property @{step="Warnung"; date="2018-01-01"; descr="User1 zu Gruppe 2 hinzugefuegt."}
	New-Object PSObject	-Property @{step="Information"; date="2018-01-02"; descr="User2 wurde in WRAD hinzugefuegt."}

)

$ArrAL_FpM = @(
	New-Object PSObject	-Property @{month="Jan."; count=4}
	New-Object PSObject	-Property @{month="Feb."; count=8}
	New-Object PSObject	-Property @{month="Maerz"; count=5}
	New-Object PSObject	-Property @{month="Apr."; count=0}
	New-Object PSObject	-Property @{month="Juni"; count=11}
)

#Last logon older than 90 Days
$ADUserLLOt90 = (Search-ADAccount -AccountInactive -UsersOnly -TimeSpan 90 |measure ).count
#Last logon between 30 and 90 Days
$ADUserLLb30a90 = (Search-ADAccount -AccountInactive -UsersOnly -TimeSpan 30 |measure ).count - $ADUserLLOt90
#Active User
$ADUserActive = (Search-ADAccount -AccountInactive -UsersOnly -TimeSpan 0 |measure ).count - $ADUserLLb30a90

$ADUserActivity = @(
    New-Object PSObject	-Property @{descr="Aelter als 90 Tage"; count=3; bckgrnd="#ff0000"}
    New-Object PSObject	-Property @{descr="Zwischen 30 und 90 Tagen"; count=10; bckgrnd="#ffff00"}
    New-Object PSObject	-Property @{descr="Aktive Benutzer"; count=87; bckgrnd="#00ff00"}
)

$ArrSA_LC = @(
	New-Object PSObject	-Property @{step="Warnung"; date="2018-01-01"; usr="M. Mustermann"; descr="User1 aus Gruppe 1 entfernt."}
	New-Object PSObject	-Property @{step="Warnung"; date="2018-01-01"; usr="M. Mustermann"; descr="User1 zu Gruppe 2 hinzugefuegt."}
	New-Object PSObject	-Property @{step="Information"; date="2018-01-02"; usr="M. Mustermann"; descr="User2 wurde in WRAD hinzugefuegt."}

)

$ArrAO_LCAD = @(
	New-Object PSObject	-Property @{step="Warnung"; date="2018-01-02"; usr="S. Achter"; descr="User2 wurde in der AD erstellt."}
	New-Object PSObject	-Property @{step="Warnung"; date="2018-01-02"; usr="S. Achter"; descr="Der Benutzer User 1 ist neu Mitglied der Gruppe 2"}
	New-Object PSObject	-Property @{step="Information"; date="2018-01-02"; usr="S. Achter"; descr="User1 wurde aus der Mitgliederliste der Guppe 1 entfernt."}

)

$ArrAO_SysLog = @(
	New-Object PSObject	-Property @{date="2018-01-01 10:00"; usr="M. Mustermann"; descr="User1 aus Gruppe 1 entfernt."}
	New-Object PSObject	-Property @{date="2018-01-01 10:01"; usr="M. Mustermann"; descr="User 1 zu Gruppen 2 hinzugefuegt."}
	New-Object PSObject	-Property @{date="2018-01-02 08:00"; usr="M. Mustermann"; descr="User 2 erstellt."}
	New-Object PSObject	-Property @{date="2018-01-02 09:00"; usr="M. Mustermann"; descr="IST-SOLL vergleich ausgeführt."}
	New-Object PSObject	-Property @{date="2018-01-02 14:00"; usr="S. Achter"; descr="IST-SOLL vergleich ausgeführt."}
	New-Object PSObject	-Property @{date="2018-01-03 08:00"; usr="A. Osen"; descr="IST-SOLL vergleich ausgeführt."}
    
)

$AllUsr = @(
	New-Object PSObject	-Property @{username="User01"; prename="User"; name="01"; mmbrships="1"}
	New-Object PSObject	-Property @{username="User02"; prename="User"; name="02"; mmbrships="0"}
)

$AllGrp = @(
	New-Object PSObject	-Property @{name="Gruppe1"; mmbrcnt="0"}
	New-Object PSObject	-Property @{name="Gruppe2"; mmbrcnt="1"}
)

#Login
$auth = New-UDAuthenticationMethod -Endpoint {
	param([PSCredential]$Credentials)

	Import-Module ADAuth

	$AuthorizedGroup = 'Administrators'

	if ($Credentials | ? {$_ | Test-ADCredential} | Test-ADGroupMembership -TargetGroup $AuthorizedGroup) {
		New-UDAuthenticationResult -Success -UserName $Credentials.UserName -Role "WRADadmin"
	} elseif ($Credentials.UserName -eq "Auditor" -and $Credentials.GetNetworkCredential().Password -eq "Auditor") {
		New-UDAuthenticationResult -Success -UserName $Credentials.UserName -Role "Auditor"
    }

	New-UDAuthenticationResult -ErrorMessage "You are not allowed to login!"
}
    
$login = new-UDLoginPage -AuthenticationMethod $auth -WelcomeText "Welcome to WRAD" -PageBackgroundColor "white" -LoginFormFontColor "black" -LoginFormBackgroundColor "grey"

#Abteilungsleiter Dashboard
$PageALDashboard = New-UDPage -Name "Abteilungsleiter" -AuthorizedRole @("WRADadmin","Abteilungsleiter") -Content {
    New-UDHeading -Content {
        New-UDButton -Text "Dashboard"
        New-UDButton -Text "Benutzer / Gruppen"
        New-UDButton -Text "Reports"
	}
    
	New-UDRow {
        #Rechtefehler
		New-UDColumn -size 4 -Content {
			New-UdGrid -Title "Rechtefehler" -Headers @("Stufe", "Datum", "Beschreibung") -Properties @("step", "date", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrAL_RF | Select step,date,descr | Out-UDGridData
			}
		}
        
        #Letzte anderungen
		New-UDColumn -size 4 -Content {
			New-UdGrid -Title "Letzte Aenderungen" -Headers @("Stufe", "Datum", "Beschreibung") -Properties @("step", "date", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrAL_LC | Select step,date,descr | Out-UDGridData
			}
		}
		#Status 
        New-UDColumn -size 4 -Content {
            New-UdGrid -Title "Status" -Headers @("Beschreibung", "Anzahl") -Properties @("descr", "count") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ADUserActivity | Select descr,count | Out-UDGridData
			}
        }
	}
	
	New-UDRow {
		#Letzte Anmeldung
		New-UDColumn -size 4 -Content {
			New-UDChart -Title "Letzte Anmledung" -Type Doughnut -RefreshInterval 5 -Endpoint { 
                $ADUserActivity | Out-UDChartData -LabelProperty "descr" -Dataset @(
				    New-UDChartDataset -DataProperty "count"  -BackgroundColor "#9055AAFF" -HoverBackgroundColor bckgrnd -Label "Users" 
               )
                
			}
		}
		
        #Letzte Anmeldung
		New-UDColumn -size 4 -Content {
			New-UDChart -Title "Letzte Anmledung" -Type Doughnut -RefreshInterval 5 -Endpoint { 
                $ADUserActivity | Out-UDChartData -LabelProperty "descr" -Dataset @( 
				    New-UDDoughnutChartDataset -DataProperty "count"  -BackgroundColor "#9055AAFF" -HoverBackgroundColor $_.bckgrnd -Label "Users" 
               )
			}
		}

		#Fehler pro Monat
		New-UDColumn -size 4 -Content {
			New-UDChart -Title "Fehler pro Monat" -Type bar -RefreshInterval 5 -Endpoint { 
				$ArrAL_FpM | Out-UDChartData -LabelProperty "month" -Dataset @(
                    New-UDChartDataset -DataProperty "count" -Label "Fehler" -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr
                )
			}
		}
	}
}

#Unable to index into an object of type System.Management.Automation.PSMemberInfoIntegratingCollection`1[System.Management.Automation.PSPropertyInfo].



#Auditor Dashboard
$PageAtDashboard = New-UDPage -Name "Auditor" -AuthorizedRole @("WRADadmin","Auditor") -Content {
    New-UDHeading -Content {
        New-UDButton -Text "Dashboard"
        New-UDButton -Text "Benutzer / Gruppen"
        New-UDButton -Text "Reports"
	}
    
	New-UDRow {
		#Fehler pro Monat
		New-UDColumn -size 6 -Content {
			New-UDChart -Title "Fehler pro Monat" -Type bar -RefreshInterval 5 -Endpoint { 
				$ArrAL_FpM | Out-UDChartData -LabelProperty "month" -Dataset @(
                    New-UDChartDataset -DataProperty "count" -Label "Fehler" -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr
                )
			}
		}
    }

    New-UDRow {
        
        #Rechtefehler
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Rechtefehler" -Headers @("Stufe", "Datum", "Beschreibung") -Properties @("step", "date", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrAL_RF | Select step,date,descr | Out-UDGridData
			}
		}

		#Status 
        New-UDColumn -size 6 -Content {
            New-UdGrid -Title "Status" -Headers @("Beschreibung", "Anzahl") -Properties @("descr", "count") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ADUserActivity | Select descr,count | Out-UDGridData
			}
        }
	}
}

#Sysadmin Dashboard
$PageSADashboard = New-UDPage -Name "System Admin" -AuthorizedRole @("WRADadmin","Sysadmin") -Content {
    New-UDHeading -Content {
		#New-UDCard -Endpoint { $User }
        New-UDButton -Text "Dashboard"
        New-UDButton -Text "Benutzer / Gruppen"
        New-UDButton -Text "Reports"
	}

    New-UDRow {
        #Rechtefehler
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Rechtefehler" -Headers @("Stufe", "Datum", "Beschreibung") -Properties @("step", "date", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrAL_RF | Select step,date,descr | Out-UDGridData
			}
		}

        #Letzte anderungen
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Letzte Aenderungen" -Headers @("Stufe", "Datum", "Benutzer", "Beschreibung") -Properties @("step", "date", "usr", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrSA_LC | Select step,date,usr,descr | Out-UDGridData
			}
		}
	}
    
	New-UDRow {
		#Fehler pro Monat
		New-UDColumn -size 6 -Content {
			New-UDChart -Title "Fehler pro Monat" -Type bar -RefreshInterval 5 -Endpoint { 
				$ArrAL_FpM | Out-UDChartData -LabelProperty "month" -Dataset @(
                    New-UDChartDataset -DataProperty "count" -Label "Fehler" -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr
                )
			}
		}

		#Status 
        New-UDColumn -size 6 -Content {
            New-UdGrid -Title "Status" -Headers @("Beschreibung", "Anzahl") -Properties @("descr", "count") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ADUserActivity | Select descr,count | Out-UDGridData
			}
        }
    }
}

#Applicatin Owner Dashboard
$PageAODashboard = New-UDPage -Name "Application Owner" -AuthorizedRole @("WRADadmin","AppOwner") -Content {
    New-UDHeading -Content {
        New-UDButton -Text "Dashboard"
        New-UDButton -Text "Reports"
        New-UDButton -Text "Logs"
        New-UDButton -Text "Einstellungen"
	}
    
    New-UDRow {
        #Letzte anderungen WRAD
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Letzte Aenderungen in WRAD" -Headers @("Stufe", "Datum", "Benutzer", "Beschreibung") -Properties @("step", "date", "usr", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrSA_LC | Select step,date,usr,descr | Out-UDGridData
			}
		}
        #Letzte anderungen AD
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Letzte Aenderungen in der AD" -Headers @("Stufe", "Datum", "Benutzer", "Beschreibung") -Properties @("step", "date", "usr", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrAO_LCAD | Select step,date,usr,descr | Out-UDGridData
			}
		}
    }

    New-UDRow {
        #Syslog
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Letzte Aenderungen in der AD" -Headers @("Datum", "Benutzer", "Beschreibung") -Properties @("date", "usr", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrAO_SysLog | Select date,usr,descr | Out-UDGridData
			}
		}
    }
}

#Authentifizierungsstelle Dashboard
$PageASDashboard = New-UDPage -Name "Authentifizierungsstelle" -AuthorizedRole @("WRADadmin","AuthStelle") -Content {
    New-UDHeading -Content {
        New-UDButton -Text "Dashboard"
        New-UDButton -Text "Benutzer / Gruppen"
        New-UDButton -Text "Reports"
	}
    
    New-UDRow {
		#Fehler pro Monat
		New-UDColumn -size 6 -Content {
			New-UDChart -Title "Fehler pro Monat" -Type bar -RefreshInterval 5 -Endpoint { 
				$ArrAL_FpM | Out-UDChartData -LabelProperty "month" -Dataset @(
                    New-UDChartDataset -DataProperty "count" -Label "Fehler" -BackgroundColor $FpMBckgrn -HoverBackgroundColor $FpMBckgrnHvr
                )
			}
		}
    }

    New-UDRow {
        #Rechtefehler
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Rechtefehler" -Headers @("Stufe", "Datum", "Beschreibung") -Properties @("step", "date", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrAL_RF | Select step,date,descr | Out-UDGridData
			}
		}

        #Letzte anderungen WRAD
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Letzte Aenderungen in WRAD" -Headers @("Stufe", "Datum", "Benutzer", "Beschreibung") -Properties @("step", "date", "usr", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrSA_LC | Select step,date,usr,descr | Out-UDGridData
			}
		}
    }
}

$UsrAGrp = New-UDPage -Name "UserUndGruppen" -AuthorizedRole @("Auditor") -Content {
    New-UDRow {
        #Alle User
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Alle User" -Headers @("Benutzername", "Vorname", "Nachname", "Mitgliedschaften") -Properties @("username", "prename", "name", "mmbrships") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$AllUsr | Select username,prename,name,mmbrships | Out-UDGridData
			}
		}
        #Alle gruppen
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Alle Gruppen" -Headers @("Name", "Mitgliederanzahl") -Properties @("name", "mmbrcnt") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$AllGrp | Select name,mmbrcnt | Out-UDGridData
			}
		}
    }
}

$Settings = New-UDPage -Name "Einstellungen" -AuthorizedRole @("Auditor") -Content {
	New-UDRow {
        #Alle User
		New-UDColumn -size 6 -Content {
			New-UDInput -Title "Settings 1" -Id "Form" -Content {
				New-UDInputField -Type 'checkbox' -Name 'Setting1' -Placeholder 'Setting 1.'
				New-UDInputField -Type 'select' -Name 'Sprache' -Placeholder 'Favorite Programming Language' -Values @("Deutsch", "Englisch")
				New-UDInputField -Type 'select' -Name 'Theme' -Placeholder 'Favorite Programming Language' -Values @("Azure", "Default")
			} -Endpoint {
				param($Setting1, $Sprache, $Theme)
				
				$theme = $Theme
			}
		}
        #Alle gruppen
		New-UDColumn -size 6 -Content {
			
		}
    }
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Get-UDDashboard | Stop-UDDashboard

#Themes Azure,Blue,Default,Earth,Green,Red
#$theme = Get-UDTheme -Name "Azure"
$theme = New-UDTheme -Name "AzureChngBtn" -Definition @{
    'UDButton' = @{
        'BackgroundColor' = '#A1220C'
    }
} -Parent Azure

Start-UDDashboard -Port 10000 -AllowHttpForLogin -Content {
    
    New-UdDashboard -Login $login -Pages @($PageALDashboard, $PageAtDashboard, $PageSADashboard, $PageAODashboard, $PageASDashboard, $UsrAGrp) -Title "Mock up Dashboards" -Color 'Black' -Theme $theme

} -Verbose -debug