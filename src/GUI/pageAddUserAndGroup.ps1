$PageAddUser = New-UDPage -Name "Add User or Group" -AuthorizedRole @("WRADadmin","DepLead") -Content {
    New-UDRow {

        #Add User
		New-UDColumn -size 6 -Content {
			New-UDInput -Title "Add User" -Id "FormAddUser" -Content {
                
                New-UDInputField -Type 'textbox' -Name 'un' -Placeholder 'Username' 
                New-UDInputField -Type 'textbox' -Name 'dn' -Placeholder 'Displayname' 
                New-UDInputField -Type 'select' -Name 'active' -Placeholder 'Enabled' -Values @("Yes", "No") -DefaultValue "Yes"
                
            } -Endpoint {
                param($un, $dn, $active)

                #boolsche Wert erfassen
                [bool]$nbld
                if($active -eq "Yes"){
                    $nbld = $true
                } else {
                    $nbld = $false
                }

                #Usereingabe prüfen
                $un = $un.trim()
                $dn = $dn.trim()

                if(-not ([string]::IsNullOrEmpty($un) -or [string]::IsNullOrEmpty($dn))){
                    
                    load-WRADModules

                    #Check for unique Username
                    if((Get-WRADUser -Reference -UserName $un).count -eq 0){
                        New-WRADUser -Reference -Username "$un" -DisplayName "$dn" -Enabled $nbld
                        Write-WRADLog -logtext "Added user $un" -level 0

                        New-UDInputAction -Toast "The user '$un' was added." -Duration 5000 -ClearInput
                    } else {
                        New-UDInputAction -Toast "The user '$un' already exists. The username must be unique." -Duration 5000
                    }
                } else {
                    #Usereingabe falsch
                    New-UDInputAction -Toast "A field is empty. Please fill all fields." -Duration 5000
                }
            }
        }

        #Add Group
		New-UDColumn -Size 6 -Content {
            New-UDInput -Title "Add Group" -Id "FormAddGroup" -Content {
                New-UDInputField -Type textbox -Name 'cmnnm' -Placeholder 'Common name' 
                New-UDInputField -Type select -Name 'grptyp' -Placeholder 'Group type' -Values @("DomainLocal", "Global", "Universal") -DefaultValue "DomainLocal"
                New-UDInputField -Type select -Name 'grptypsec' -Placeholder 'Group type security' -Values @("Security", "Distribution") -DefaultValue "Security"
            } -Endpoint {
                param($cmnnm, $grptyp, $grptypsec)
                $cmnnm = $cmnnm.trim()

                if( -not [string]::IsNullOrEmpty($cmnnm)){

                    load-WRADModules

                    #Save Group
                    New-WRADGroup -Reference -CommonName "$cmnnm" -GroupType $grptyp -GroupTypeSecurity $grptypsec
                    Write-WRADLog -logtext "Added Group $cmnnm" -level 0
                    New-UDInputAction -Toast "The group '$cmnnm' is saved." -ClearInput -Duration 5000
                } else {
                    New-UDInputAction -Toast "Please give the group a CommonName." -Duration 5000
                }
            }
        }
    }
}