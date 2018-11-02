$Script:ActualWRADSettings = Get-WRADSetting

$PageSettings = New-UDPage -Name "Einstellungen" -AuthorizedRole @("WRADadmin","Auditor") -Content {
    New-UDRow {
        New-UDColumn -size 3 -Content {
			
		}
        #Alle User
		New-UDColumn -size 6 -Content {
			New-UDInput -Title "Settings" -Id "Form" -Content {
                
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[8].SettingName -Placeholder 'AD Base' -DefaultValue $Script:ActualWRADSettings[8].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[0].SettingName -Placeholder 'AD Gruppe: Abteilungsleiter' -DefaultValue $Script:ActualWRADSettings[0].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[1].SettingName -Placeholder 'AD Gruppe: Auditor' -DefaultValue $Script:ActualWRADSettings[1].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[2].SettingName -Placeholder 'AD Gruppe: System Administrator' -DefaultValue $Script:ActualWRADSettings[2].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[3].SettingName -Placeholder 'AD Gruppe: Application Owner' -DefaultValue $Script:ActualWRADSettings[3].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[5].SettingName -Placeholder 'Log-Dateipfad' -DefaultValue $Script:ActualWRADSettings[5].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[6].SettingName -Placeholder 'Syslog Server' -DefaultValue $Script:ActualWRADSettings[6].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[7].SettingName -Placeholder 'Syslog Protokoll' -DefaultValue $Script:ActualWRADSettings[7].SettingValue
                New-UDInputField -Type 'select' -Name $Script:ActualWRADSettings[4].SettingName -Placeholder 'Externes Logging' -Values @("none", "file", "syslog") -DefaultValue $Script:ActualWRADSettings[4].SettingValue
                
            } -Endpoint {
                param($SearchBase, $ADRoleDepartmentLead, $ADRoleAuditor, $ADRoleSysAdmin, $ADRoleApplOwner, $LogFilePath, $LogSyslogServer, $LogSyslogServerProtocol, $LogExternal)

                #Setting up input
                $WRADSettingsNew = @()
                $WRADSettingsNew += $ADRoleDepartmentLead
                $WRADSettingsNew += $ADRoleAuditor
                $WRADSettingsNew += $ADRoleSysAdmin
                $WRADSettingsNew += $ADRoleApplOwner
                $WRADSettingsNew += $LogExternal
                $WRADSettingsNew += $LogFilePath
                $WRADSettingsNew += $LogSyslogServer
                $WRADSettingsNew += $LogSyslogServerProtocol
                $WRADSettingsNew += $SearchBase
                                
                #$WRADSettingsActual = Get-WRADSetting

                #Look for changes
                $ns = 0
                $newSettings = "Update-WRADSetting"
                Write-UDLog -Message "Check settings"

                For($i=0; $i -le $WRADSettingsNew.length-1; $i++) {
                   
                    if($Script:ActualWRADSettings[$i].SettingValue -ne $WRADSettingsNew[$i]){
                        Write-UDLog -Message "New Setting $($WRADSettingsNew[$i])" -Level Info
                        #$Script:ActualWRADSettings[$i].SettingValue = $WRADSettingsNew[$i]
                        $ns = 1

                        $newSettings += " -$($Script:ActualWRADSettings[$i].SettingName) '$($WRADSettingsNew[$i])'"
                    }
                }
                
                #Save new settings
                if($ns){
                    if(!(get-module WRADDBCommands)){
                        Import-Module $Script:ScriptPath\..\modules\WRADDBCommands.psm1
                        Write-UDLog -Message "Import Module WRADCommands"
                    }

                    $Script:ActualWRADSettings = Get-WRADSetting

                    try {
                        Write-UDLog -Message $newSettings
                        Invoke-Expression $newSettings
                        
                    } 
                    catch {
                        Write-UDLog -Message "CATCH: $($_.Exception.Message)"
                    }
                    
                }
                          
                Write-UDLog -Message "End of code" -Level Info
                New-UDInputAction -RedirectUrl "/Einstellungen"

            }
		}
        #Alle gruppen
		New-UDColumn -size 3 -Content {
			
		}
    }
}