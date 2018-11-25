<#
Was geht nicht oder wurde keine Lösung gefunden:

Windows Server 2016
.Net 4.7.2
UniversalDashboard 2.1.0

1)
New-UDDashboard -EndpointInitialization
--> New-UDEndpointInitialization -Modul OK -Function OK -Variable Error
Fehler:
New-UDEndpointInitialization : Access to the path 'C:\Data\BTI7301-2018-WRAD\src\GUI' is denied.
At C:\Data\BTI7301-2018-WRAD\src\GUI\UDGUI_Lokal.ps1:51 char:25
+ ... DEndpoint = New-UDEndpointInitialization -Module $PSScriptRoot\..\mod ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [New-UDEndpointInitialization], UnauthorizedAccessException
    + FullyQualifiedErrorId : System.UnauthorizedAccessException,UniversalDashboard.Cmdlets.NewEndpointInitializationCommand

Sobald man die Variable auskommentiert gibt es keinen Fehler mehr. Möchte dort den Pfad zum Script angeben ($PSScriptRoot)

2)
Button in einem New-UDGrid Element einbinden, funktioniert nicht. Mit dem New-UDLink Element funktioniert es.
Sowohl Version UniversalDashboard 2.1.0  wie auch UniversalDashboard 2.2.0-beta1
Auf jeder Zeile des Grids soll ein Button oder ähnliches sein, dass eine Funktion auslösen kann. Vielleicht auch ein Link mit einer OnClick-Action, da man den Button nicht umdesignen kann.

Code: 
ForEach($User in $AllUser){
    $AllUserGrid += @{Username = $User.Username; DisplayName = $User.DisplayName; CreatedDate = $User.CreatedDate; Enabled = $User.Enabled; Edit =(New-UDButton -Text "Edit")} 
}

Error: this.state.events.map is not a function

3) New-UDInput ... -Endpoint {} -ArgumentList
Beim Endpoint einesInput Element gibt es keine Argument List Property

4)Endpoint einer Dynamischen Seite hat keinen Zugriff auf die $Script oder $Global Variablen

Beim Versuch das Modul WRADDBCommands zuladen oder beim auslesen von daten über das Modul.

#10:52:32 ExecutionService Error executing endpoint script. The variable '$Global:WRADDBConnection' cannot be retrieved because it has not been set.

5)
Ich weiss nicht wie ich ein Grid neu laden kann. Wenn man zum Beispiel ein User löscht soll dieser aus der Tabelle verschwinden. Für Prototyp nicht wichtig.

#>

$Script:ScriptPath = $PSScriptRoot
$ScrptRt = $PSScriptRoot

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

function load-WRADDBCommands {
    Param()
    try {
        if(!(get-module WRADDBCommands)){
            Import-Module $Script:ScriptPath\..\modules\WRADDBCommands.psm1
            write-host "Import Module WRADCommands"
        }
    }
    catch {
        Write-Error -Message $_.Exception.Message
        Write-UDLog -Level Warning -Message "Could not load WRAD DB Commands."
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
load-WRADDBCommands

$InitiateWRADEndpoint = New-UDEndpointInitialization -Module $PSScriptRoot\..\modules\WRADDBCommands.psm1 -Function enable-WRADLogging,load-WRADDBCommands #-Variable $ScrptRt

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
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Edit User

$AllUserGrid = @()
$AllUser = Get-WRADUser -Reference
Write-UDLog -Level Warning -Message "There are $($AllUser.Count) Users"
ForEach($User in $AllUser){
    $AllUserGrid += @{Username = $User.Username; DisplayName = $User.DisplayName; CreatedDate = $User.CreatedDate; Enabled = $User.Enabled; Edit =(New-UDLink -Text "Edit" -Url "/EditUser/$($User.ObjectGUID)")} 
    #$AllUserGrid += @{Username = $User.Username; DisplayName = $User.DisplayName; CreatedDate = $User.CreatedDate; Enabled = $User.Enabled; Edit =(New-UDButton -Text "Edit")} 

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
    }#

    #load-WRADDBCommands
    $Script:Scriptpath = $ArgumentList[0]
    $Global:WRADDBConnection = $ArgumentList[1]

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
                
                    Load Module
                    if(!(get-module WRADDBCommands)){
                        Import-Module $Script:Scriptpath\..\modules\WRADDBCommands.psm1
                        Write-UDLog -Level Warning -Message "Import Module WRADCommands"
                    }

                    #load-WRADDBCommands

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
            $UsrGrp = @()
            ForEach($group in $Script:EUgroup){
                $newgroup = Get-WRADGroup -Reference -ObjectGUID $group.GroupObjectGUID
                $UsrGrp += @{ GroupName = $newgroup.CommonName; Edit =(New-UDLink -Text "Remove" -Url "/RemUsrFrmGrp/$($Script:EUuser.ObjectGUID)/$($group.GroupObjectGUID)")}
            }
            New-UDGrid -Title "Member of" -Header @("GroupName", "Edit") -Properties @("GroupName", "Edit") -Endpoint {
                $UsrGrp | Out-UDGridData
            }
        } 
    } 
} -ArgumentList $PSScriptRoot,$Global:WRADDBConnection

$PageRemUsrFrmGrp = New-UDPage -URL "/RemUsrFrmGrp/:usrguid/:grpguid" -AuthorizedRole @("WRADadmin","Auditor") -Endpoint {
    param($usrguid, $grpguid)
    #10:52:32 ExecutionService Error executing endpoint script. The variable '$Global:WRADDBConnection' cannot be retrieved because it has not been set.
    <#$date = Get-Date -UFormat "%Y%m%d"
    Enable-UDLogging -FilePath "C:\Data\Logs\UDLog_$date.txt" -Level Warning
    Write-UDLog -Level Warning -Message "Delete Group $usrguid from User $grpguid"#>
    enable-WRADLogging


    $Script:Scriptpath = $ArgumentList[0]
    $Global:WRADDBConnection = $ArgumentList[1]

    load-WRADDBCommands
    enable-WRADLogging
    
	<#Load Module 
    if(!(get-module WRADDBCommands)){
#WARNING: Hard Coded Path. Works only on BFH Server--------------------------------------------------------------------------------------------------------------------------------
		Import-Module C:\Data\BTI7301-2018-WRAD\src\modules\WRADDBCommands.psm1
#--------------------------------------------------------------------------------------------------------------------------------
		Write-UDLog -Level Warning -Message "Import Module WRADCommands"
	}#>
	
    Write-UDLog -Level Warning -Message "Remove now"
	Remove-WRADGroupOfUser -Reference -UserObjectGUID $usrguid -GroupObjectGUID $grpguid

    New-UDInputAction -RedirectUrl "/Edit-User"
} -ArgumentList $PSScriptRoot,$Global:WRADDBConnection
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
	New-UDRow {
		
		New-UDColumn -Size 6 -Content {
			$grpchldgrp = Get-WRADGroupOfGroup -Reference -ChildGroupObjectGUID $grpguid 

			New-UDGrid -Title "Member of Groups" -Header @("CommonName", "Create date", "Edit") -Properties @("CommonName", "CreatedDate", "Edit") -Endpoint {
                $grpchldgrp | Out-UDGridData
            }
		}
		
		New-UDColumn -Size 6 -Content {
			$grpprntgrp = Get-WRADGroupOfGroup -Reference -ParentGroupObjectGUID $grpguid 

			New-UDGrid -Title "Groups in Group" -Header @("CommonName", "Create date", "Edit") -Properties @("CommonName", "CreatedDate", "Edit") -Endpoint {
                $grpprntgrp | Out-UDGridData
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
    
    New-UDDashboard -Login $login -Pages @($PageSettings, $PageAddUser, $PageEditUser, $PageEditUserDyn, $PageRemUsrFrmGrp) -Title "Mock up Dashboards" -Color 'Black' -Theme $theme -EndpointInitialization $InitiateWRADEndpoint
    
}
#-Verbose -debug