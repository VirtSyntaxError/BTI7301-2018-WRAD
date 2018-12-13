
$PageSettings = New-UDPage -Name "Settings" -AuthorizedRole @("WRADadmin","Auditor") -Content {
    New-UDRow {
        New-UDColumn -size 3 -Content {
			
		}
        #Alle User
		New-UDColumn -size 6 -Content {
            $Script:ActualWRADSettings = Get-WRADSetting

			New-UDInput -Title "Settings" -Id "FormSettings" -Content {
                
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[8].SettingName -Placeholder 'AD Base' -DefaultValue $Script:ActualWRADSettings[8].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[0].SettingName -Placeholder 'AD Group: Department Leader' -DefaultValue $Script:ActualWRADSettings[0].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[1].SettingName -Placeholder 'AD Group: Auditor' -DefaultValue $Script:ActualWRADSettings[1].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[2].SettingName -Placeholder 'AD Group: System Administrator' -DefaultValue $Script:ActualWRADSettings[2].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[3].SettingName -Placeholder 'AD Group: Application Owner' -DefaultValue $Script:ActualWRADSettings[3].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[5].SettingName -Placeholder 'Logfilepath' -DefaultValue $Script:ActualWRADSettings[5].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[6].SettingName -Placeholder 'Syslog server' -DefaultValue $Script:ActualWRADSettings[6].SettingValue
                New-UDInputField -Type 'textbox' -Name $Script:ActualWRADSettings[7].SettingName -Placeholder 'Syslog protocol' -DefaultValue $Script:ActualWRADSettings[7].SettingValue
                New-UDInputField -Type 'select' -Name $Script:ActualWRADSettings[4].SettingName -Placeholder 'External logging' -Values @("none", "file", "syslog") -DefaultValue $Script:ActualWRADSettings[4].SettingValue
                
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
                Write-UDLog -Level Warning -Message "Check settings"

                For($i=0; $i -le $WRADSettingsNew.length-1; $i++) {
                   
                    if($Script:ActualWRADSettings[$i].SettingValue -ne $WRADSettingsNew[$i]){
                        Write-UDLog -Level Warning -Message "New Setting $($WRADSettingsNew[$i])" 
                        #$Script:ActualWRADSettings[$i].SettingValue = $WRADSettingsNew[$i]
                        $ns = 1

                        $newSettings += " -$($Script:ActualWRADSettings[$i].SettingName) '$($WRADSettingsNew[$i])'"
                    }
                }
                
                #Save new settings
                if($ns){
                    if(!(get-module WRADDBCommands)){
                        Import-Module $Script:ScriptPath\..\modules\WRADDBCommands.psm1
                        Write-UDLog -Level Warning -Message "Import Module WRADCommands"
                    }

                    try {
                        Write-UDLog -Level Warning -Message $newSettings
                        Invoke-Expression $newSettings
                        
                    } 
                    catch {
                        Write-UDLog -Level Warning -Message "CATCH: $($_.Exception.Message)"
                    }

                    $Script:ActualWRADSettings = Get-WRADSetting
                    
                }
                          
                Write-UDLog -Level Warning -Message "End of code 'insert settings'"
                New-UDInputAction -RedirectUrl "/Settings"

            }
		}
        #Alle gruppen
		New-UDColumn -size 3 -Content {
			
		}
    }
}