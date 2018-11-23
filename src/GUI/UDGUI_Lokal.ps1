$Script:ScriptPath = $PSScriptRoot

if(!(get-module UniversalDashboard)){
	Import-Module UniversalDashboard
    write-host "Import Module UniversalDasboard"
}

if(!(get-module WRADDBCommands)){
    Import-Module $Script:ScriptPath\..\modules\WRADDBCommands.psm1
    write-host "Import Module WRADCommands"
}

$date = Get-Date -UFormat "%Y%m%d"
Enable-UDLogging -FilePath "C:\Data\Logs\UDLog_$date.txt" -Level Warning

#----------------------------------------------------------------------------------------------------------------------------------------------------------------

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

$ADUserActivity = @(
    New-Object PSObject	-Property @{descr="Aelter als 90 Tage"; count=3; bg="#90ff0000"}
    New-Object PSObject	-Property @{descr="Zwischen 30 und 90 Tagen"; count=10; bg="#90ffff00"}
    New-Object PSObject	-Property @{descr="Aktive Benutzer"; count=87; bg="#9000ff00"}
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
	New-Object PSObject	-Property @{date="2018-01-02 09:00"; usr="M. Mustermann"; descr="IST-SOLL vergleich ausgef�hrt."}
	New-Object PSObject	-Property @{date="2018-01-02 14:00"; usr="S. Achter"; descr="IST-SOLL vergleich ausgef�hrt."}
	New-Object PSObject	-Property @{date="2018-01-03 08:00"; usr="A. Osen"; descr="IST-SOLL vergleich ausgef�hrt."}
    
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

#Abteilungsleiter Dashboard
$PageALDashboard = New-UDPage -Name "Abteilungsleiter" -AuthorizedRole @("WRADadmin","Abteilungsleiter") -Content {
    New-UDHeading -Content {

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
				    New-UDChartDataset -DataProperty "count"  -BackgroundColor "#9055AAFF" -HoverBackgroundColor "bg" -Label "Users" 
               )
                
			}
		}
		
        #Letzte Anmeldung
		New-UDColumn -size 4 -Content {
			New-UDChart -Title "Letzte Anmledung" -Type Doughnut -RefreshInterval 5 -Endpoint { 
                $ADUserActivity | Out-UDChartData -LabelProperty "descr" -Dataset @( 
                    $test = "#90ff0000"
                    #Write-Debug bckgrnd
				    New-UDDoughnutChartDataset -DataProperty "count"  -BackgroundColor "#9055AAFF" -HoverBackgroundColor "#90FF0000" -Label "Users" 
               )
			}
            #Unable to index into an object of type System.Management.Automation.PSMemberInfoIntegratingCollection`1[System.Management.Automation.PSPropertyInfo].

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
        #New-UDButton -Text "Dashboard"
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

#---------------------------------------------------------------------------------------------------------------

#Load outsourced Pages
. .\pageSettings.ps1
. .\pageAddUserAndGroup.ps1
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Edit User

$AllUserGrid = @()
$AllUser = Get-WRADUser -Reference
Write-UDLog -Level Warning -Message "There are $($AllUser.Count) Users"
ForEach($User in $AllUser){
    $AllUserGrid += @{Username = $User.Username; DisplayName = $User.DisplayName; CreatedDate = $User.CreatedDate; Enabled = $User.Enabled; Edit =(New-UDLink -Text "Edit" -Url "/EditUser/$($User.ObjectGUID)")} 
}

$PageEditUser = New-UDPage -Name "Edit User" -AuthorizedRole @("WRADadmin","Auditor") -AutoRefresh -RefreshInterval 30 -Content {
    
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            New-UDGrid -Title "All user" -Header @("Username", "Displayname", "Create date", "Enabled", "Edit") -Properties @("Username", "DisplayName", "CreatedDate", "Enabled", "Edit") -Endpoint {
                $AllUserGrid | Out-UDGridData
            }
        }
    }
}

$PageEditUserDyn = New-UDPage -URL "/EditUser/:usrguid" -AuthorizedRole @("WRADadmin","Auditor") -Endpoint {
    param($usrguid)

    #Load Module
    if(!(get-module WRADDBCommands)){
#WARNING: Hard Coded Path. Works only on BFH Server--------------------------------------------------------------------------------------------------------------------------------
        Import-Module C:\Data\BTI7301-2018-WRAD\src\modules\WRADDBCommands.psm1
#--------------------------------------------------------------------------------------------------------------------------------
        Write-UDLog -Level Warning -Message "Import Module WRADCommands"
    }

    #Get User and make him editable
    Write-UDLog -Level Warning -Message "Get User: $usrguid"
    $Script:EUuser = Get-WRADUser -Reference -ObjectGUID $usrguid
    $Script:EUgroup = Get-WRADGroupOfUser -Reference -UserObjectGUID $usrguid
        
    if($Script:EUuser.Enabled){
        $EUenabled = "Yes"
    } else {
        $EUenabled = "No"
    }

    New-UDRow {
        New-UDColumn -Size 6 -Content {
            New-UDInput -Title "Edit User" -Id "FormEditUser" -Content {
                New-UDInputField -Type 'textbox' -Name 'euun' -Placeholder 'Username' -DefaultValue $Script:EUuser.UserName
                New-UDInputField -Type 'textbox' -Name 'eudn' -Placeholder 'Displayname' -DefaultValue $Script:EUuser.DisplayName
                New-UDInputField -Type 'select' -Name 'euactive' -Placeholder 'Enabled' -Values @("Yes", "No") -DefaultValue $EUenabled
            } -Endpoint {
                param($euun, $eudn, $euactive)
                

                if($euactive -eq "Yes"){
                    $eunbld = $true
                } else {
                    $eunbld = $false
                }

                if(($Script:EUuser.Username -ne $euun) -or ($Script:EUuser.DisplayName -ne $eudn) -or ($Script:EUuser.Enabled -ne $eunbld)){
                
                    #Load Module
                    if(!(get-module WRADDBCommands)){
                        Import-Module $Script:Scriptpath\..\modules\WRADDBCommands.psm1
                        Write-UDLog -Level Warning -Message "Import Module WRADCommands"
                    }

                    #Update User
                    Write-UDLog -Level Warning -Message "Update User $euun $eudn $eunbld"
                    Update-WRADUser -Reference -ObjectGUID $usrguid -UserName $euun -DisplayName $eudn -Enabled $eunbld

                    $AllUserGrid = Get-WRADUser
                    New-UDInputAction -Toast "The user '$euun' is edited." -Duration 5000
                } else {
                    New-UDInputAction -Toast "The user '$euun' didn't change." -Duration 5000
                }
            } 
        }
        New-UDColumn -Size 6 -Content {
            If($Script:EUgroup.count -gt 0){
                $UsrGrp = @()
                ForEach($group in $Scipt:EUgroup){
                    $newgroup = Get-WRADGroup -Reference -ObjectGUID $group.ObjectGUID
                    $UsrGrp += @{ GroupName = $newgroup.CommonName; Edit =(New-UDLink -Text "Remove" -Url "/RemUsrFrmGrp/$($Script:EUuser.ObjectGUID)/$($group.ObjectGUID)")}
                }
            }
        } 
    } 
}

$PageRemUsrFrmGrp = New-UDPage -URL "/RemUsrFrmGrp/:usrguid/:grpguid" -AuthorizedRole @("WRADadmin","Auditor") -Endpoint {
    param($usrguid, $grpguid)

	#Load Module
    if(!(get-module WRADDBCommands)){
#WARNING: Hard Coded Path. Works only on BFH Server--------------------------------------------------------------------------------------------------------------------------------
		Import-Module C:\Data\BTI7301-2018-WRAD\src\modules\WRADDBCommands.psm1
#--------------------------------------------------------------------------------------------------------------------------------
		Write-UDLog -Level Warning -Message "Import Module WRADCommands"
	}
	
	Remove-WRADGroupOfUser -Reference -UserObjectGUID $usrguid -GroupObjectGUID $grpguid

    New-UDInputAction -RedirectUrl "/Edit-User/"
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Edit Group
$AllGroupGrid = @()
$AllGroups = Get-WRADGroup -Reference
Write-UDLog -Level Warning -Message "There are $($AllGroups.Count) Users"
ForEach($Group in $AllGroups){
    $AllGroupGrid += @{CommonName = $Group.CommonName; CreatedDate = $User.CreatedDate;  Edit =(New-UDLink -Text "Edit" -Url "/EditGroup/$($Group.ObjectGUID)")} 
}

$PageEditGroup = New-UDPage -Name "Edit Group" -AuthorizedRole @("WRADadmin","Auditor") -AutoRefresh -RefreshInterval 30 -Content {
    
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            New-UDGrid -Title "All user" -Header @("CommonName", "Create date", "Edit") -Properties @("CommonName", "CreatedDate", "Edit") -Endpoint {
                $AllGroupGrid | Out-UDGridData
            }
        }
    }
}

$AllGrpFGrp = @();
$AllGrpFUsr = @();
$PageEditGroupDyn = New-UDPage -URL "/EditGroup/:grpguid" -AuthorizedRole @("WRADadmin","Auditor") -Endpoint {
	param($grpguid)

	#Load Module
    if(!(get-module WRADDBCommands)){
#WARNING: Hard Coded Path. Works only on BFH Server--------------------------------------------------------------------------------------------------------------------------------
		Import-Module C:\Data\BTI7301-2018-WRAD\src\modules\WRADDBCommands.psm1
#--------------------------------------------------------------------------------------------------------------------------------
		Write-UDLog -Level Warning -Message "Import Module WRADCommands"
	}

	$Script:EGgroup = Get-WRADGroup -Reference -ObjectGUID $grpguid

	New-UDRow {
		New-UDColumn -Size 6 -Content {
			New-UDInput -Title "Edit Group" -Id "FormEditGroup" -Content {
                New-UDInputField -Type 'textbox' -Name 'egcn' -Placeholder 'Common Name' -DefaultValue $Script:EGgroupCommonName
				New-UDInputField -Type select -Name 'eggrptyp' -Placeholder 'Group type' -Values @("DomainLocal", "Global", "Universal") -DefaultValue $Script:EGgroup.GroupType
                New-UDInputField -Type select -Name 'eggrptypsec' -Placeholder 'Group type security' -Values @("Security", "Distribution") -DefaultValue $Script:EGgroup.GroupTypeSecurity
            } -Endpoint {
				param($egcn, $eggrptyp, $eggrptypsec)
				
				if(($Script:EGgroup.CommonName -ne $egcn) -or ($Script:EGgroup.GroupType -ne $eggrptyp) -or ($Script:EGgroup.GroupTypeSecurity -ne $eggrptypsec)){
					#Load Module
                    if(!(get-module WRADDBCommands)){
                        Import-Module $Script:Scriptpath\..\modules\WRADDBCommands.psm1
                        Write-UDLog -Level Warning -Message "Import Module WRADCommands"
                    }

                    #Update Group
                    Write-UDLog -Level Warning -Message "Update Group $egcn $eggrptyp $eggrptypsec"
                    Update-WRADUser -Reference -ObjectGUID $grpguid -CommonName $egcn -GroupType $eggrptyp -GRoupTypeSecurity $eggrptypsec

                    New-UDInputAction -Toast "The user '$egcn' is edited." -Duration 5000
				}
			}
		}
		New-UDColumn -Size 6 -Content {
			$grpfgrp = Get-WRADGroupOfGroup -Reference -GroupObjectGUID $grpguid 
			#Name allocation

			New-UDGrid -Title "Group of Groups" -Header @("CommonName", "Create date", "Edit") -Properties @("CommonName", "CreatedDate", "Edit") -Endpoint {
                $AllGroupGrid | Out-UDGridData
            }
		}
	}
	New-UDRow {
		New-UDColumn -Size 3 -Content {

		}
		New-UDColumn -Size 6 -Content {
			$grpfusr = Get-WRADGroupOfUser -Reference -GroupObjectGUID $grpguid
			ForEach($user in $grpfusr){
				$UsrInGrp = Get-WRADUser -ObjectGUID $user.UserObjectGUID

				if($UsrInGrp.Enabled){
					$nbld = Yes;
				} else {
					$nbld = No;
				}

				$AllGrpFUsr += @{Username = $UsrInGrp.UserName; DisplayName = $UsrInGrp.DisplayName; Enabled = $nbld}
			}
			New-UDGrid -Title "User in Group" -Header @("Username", "DisplayName", "Enabled") -Properties @("Username", "DisplayName", "Enabled") -Endpoint {
                $AllGrpFUsr | Out-UDGridData
            }
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
    
    New-UDDashboard -Login $login -Pages @($PageALDashboard, $PageAtDashboard, $PageSADashboard, $PageAODashboard, $PageASDashboard, $UsrAGrp, $PageSettings, $PageAddUser, $PageEditUser, $PageEditUserDyn) -Title "Mock up Dashboards" -Color 'Black' -Theme $theme
    
}
#-Verbose -debug