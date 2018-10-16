if(!(get-module UniversalDashboard)){
	Import-Module UniversalDashboard
}
$SearchBase = (Get-ADDomain).DistinguishedName

$LogonList = @()
#Use LastLogonTimestamp when multiple DCs are in use!
#$OlderUser = (Get-ADUser -Filter * -Properties LastLogonTimestamp | where {$_.LastLogonTimestamp -lt (get-date).AddDays(-90).ToInt64()}).Count
$InactiveUser = (Search-ADAccount -AccountInactive -UsersOnly -TimeSpan 90 |measure ).count
$DeactivatedUser = (Search-ADAccount -AccountDisabled -UsersOnly -SearchBase $SearchBase |measure).count
$ExpiredUser = (Search-ADAccount -AccountExpired -UsersOnly |measure).count
$AllUser = (Get-ADUser -Filter * |measure).count
$ActiveUser = $AllUser - $InactiveUser
$InactiveUserChart = New-Object PSobject
$InactiveUserChart | Add-Member -membertype noteproperty -Name "Name" -Value "Logon older than 90 days"
$InactiveUserChart | Add-Member -membertype noteproperty -Name "Count" -Value $InactiveUser
$LogonList += $InactiveUserChart
$ActiveUserChart = New-Object PSobject
$ActiveUserChart | Add-Member -membertype noteproperty -Name "Name" -Value "Logon in last 90 days"
$ActiveUserChart | Add-Member -membertype noteproperty -Name "Count" -Value $ActiveUser
$LogonList += $ActiveUserChart
$ExpiredUserChart = New-Object PSobject
$ExpiredUserChart | Add-Member -membertype noteproperty -Name "Name" -Value "Expired Users"
$ExpiredUserChart | Add-Member -membertype noteproperty -Name "Count" -Value $ExpiredUser
$LogonList += $ExpiredUserChart
$DeactivatedUserChart = New-Object PSobject
$DeactivatedUserChart | Add-Member -membertype noteproperty -Name "Name" -Value "Deactivated Users"
$DeactivatedUserChart | Add-Member -membertype noteproperty -Name "Count" -Value $DeactivatedUser
$LogonList += $DeactivatedUserChart

$LastLogon = New-Object PSobject
$LastLogon | Add-Member -membertype noteproperty -Name "Name" -Value "Logon in last 90 days"
$LastLogon | Add-Member -membertype noteproperty -Name "Inactive" -Value $InactiveUser
$LastLogon | Add-Member -membertype noteproperty -Name "Active" -Value $ActiveUser
$LastLogon | Add-Member -membertype noteproperty -Name "Deactivated" -Value $DeactivatedUser
$LastLogon | Add-Member -membertype noteproperty -Name "Expired" -Value $ExpiredUser

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
    New-Object PSObject	-Property @{descr="Aelter als 90 Tage"; count=3; bckgrnd="#80ff0000"}
    New-Object PSObject	-Property @{descr="Zwischen 30 und 90 Tagen"; count=10; bckgrnd="#80ffff00"}
    New-Object PSObject	-Property @{descr="Aktive Benutzer"; count=87; bckgrnd="#8000ff00"}
)


$auth = New-UDAuthenticationMethod -Endpoint {
	param([PSCredential]$Credentials)

	Import-Module ADAuth

	$AuthorizedGroup = 'Administrators'

	if ($Credentials | ? {$_ | Test-ADCredential} | Test-ADGroupMembership -TargetGroup $AuthorizedGroup) {
		New-UDAuthenticationResult -Success -UserName $Credentials.UserName
	}

	New-UDAuthenticationResult -ErrorMessage "You are not allowed to login!"
}
    
$login = new-UDLoginPage -AuthenticationMethod $auth -WelcomeText "Welcome to WRAD" -PageBackgroundColor "white" -LoginFormFontColor "black" -LoginFormBackgroundColor "grey"

$PageALDashboard = New-UDPage -Name "Abteilungsleiter" -Content {
    New-UDHeading -Content {
		New-UDCard -Endpoint { $User }
	}
    
	New-UDRow {
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Rechtefehler" -Headers @("Stufe", "Datum", "Beschreibung") -Properties @("step", "date", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrAL_RF | Select step,date,descr | Out-UDGridData
			}
		}
    
		New-UDColumn -size 6 -Content {
			New-UdGrid -Title "Letzte Aenderungen" -Headers @("Stufe", "Datum", "Beschreibung") -Properties @("step", "date", "descr") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ArrAL_LC | Select step,date,descr | Out-UDGridData
			}
		}
	}
	
	New-UDRow {
		#Letzte Anmeldung
		New-UDColumn -size 6 -Content {
			New-UDChart -Title "Letzte Anmledung" -Type Doughnut -RefreshInterval 5 -Endpoint { 
                $ADUserActivity | Out-UDChartData -LabelProperty "descr" -Dataset @(
				    New-UDChartDataset -DataProperty "count"  -Label "Users" -BackgroundColor "#9055AAFF" -HoverBackgroundColor "#90ffffff"
               )
                
			}
		}
		
		#Fehler pro Monat
		New-UDColumn -size 6 -Content {
			New-UDChart -Title "Fehler pro Monat" -Type bar -RefreshInterval 5 -Endpoint { 
				$ArrAL_FpM | Out-UDChartData -LabelProperty "month" -Dataset @(
                    New-UDChartDataset -DataProperty "count" -Label "Fehler" -BackgroundColor "#80990000" -HoverBackgroundColor "#80ff0000"
                )
			}
		}
	}
	
	New-UDRow {
		#Status 
        New-UDColumn -size 6 -Content {
            New-UdGrid -Title "Status" -Headers @("Beschreibung", "Anzahl") -Properties @("descr", "count") -AutoRefresh -RefreshInterval 60 -Endpoint {
				$ADUserActivity | Select descr,count | Out-UDGridData
			}
        }
	}
}

Get-UDDashboard | Stop-UDDashboard

Start-UDDashboard -Port 10000 -AllowHttpForLogin -Content {

    New-UdDashboard -Login $login -Pages @($PageALDashboard) -Title "Mock up Dashboards" -Color 'Black'

} -Verbose -debug