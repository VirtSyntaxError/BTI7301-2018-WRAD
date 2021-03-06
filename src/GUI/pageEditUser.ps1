#Edit User
$PageEditUser = New-UDPage -Name "Edit User" -AuthorizedRole @("WRADadmin","DepLead") -AutoRefresh -RefreshInterval 30 -Content {
    #Show User
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            #List All User
            New-UDGrid -Title "All user" -Header @("Username", "Displayname", "Create date", "Enabled", "Edit") -Properties @("Username", "DisplayName", "CreatedDate", "Enabled", "Edit") -Endpoint {
                
                $Global:WRADDBConnection = $ArgumentList[0].dbconnection

                $AllUserGrid = @()
                $AllUser = Get-WRADUser -Reference

                ForEach($User in $AllUser){
                    $AllUserGrid += @{Username = $User.Username; DisplayName = $User.DisplayName; CreatedDate = $User.CreatedDate; Enabled = $User.Enabled; Edit =(New-UDLink -Text "Edit" -Url "/EditUser/$($User.ObjectGUID)")} 
                }
                
                $AllUserGrid | Out-UDGridData
            } -ArgumentList $WRADEndpointVar
        }
    }
}

$PageEditUserDyn = New-UDPage -URL "/EditUser/:usrguid" -ArgumentList $WRADEndpointVar -AuthorizedRole @("WRADadmin","DepLead") -Endpoint {
    param($usrguid)
    #Edit User details with Memberships

    $Script:Scriptpath = $ArgumentList[0].scrptroot
    
    $UsrUN = (Get-WRADUser -Reference -ObjectGUID $usrguid).UserName

    load-WRADModules
    enable-WRADLogging
    
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #Detailed View of User
            $Script:EUuser = Get-WRADUser -Reference -ObjectGUID $usrguid
  
            if($Script:EUuser.Enabled){
                $EUenabled = "Yes"
            } else {
                $EUenabled = "No"
            }

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
                    #Update User

                    Update-WRADUser -Reference -ObjectGUID $usrguid -UserName $euun -DisplayName $eudn -Enabled $eunbld
                    Write-WRADLog -logtext "Update User $euun" -level 0
                    New-UDInputAction -Toast "The user '$euun' is edited." -Duration 5000
                } else {
                    New-UDInputAction -Toast "The user '$euun' didn't change." -Duration 5000
                }
            }  
        } 
        New-UDColumn -Size 6 -Content {
            #Membership of User
            $Script:EUgroup = Get-WRADGroupOfUser -Reference -UserObjectGUID $usrguid

            $UsrGrp = @()
            ForEach($group in $Script:EUgroup){
                $newgroup = Get-WRADGroup -Reference -ObjectGUID $group.GroupObjectGUID
                

                $lnkremusr = New-UDElement -Tag "a" -Attributes @{
                    className = "btn"
                    target = "_self"
                    href = "$usrguid"
                    onClick = {
                        #Remove selected Group from Group
                        Remove-WRADGroupOfUser -Reference -UserObjectGUID $usrguid -GroupObjectGUID $newgroup.ObjectGUID
                        Write-WRADLog -logtext "Removed User $UsrUN from Group $($newgroup.CommonName)" -level 0
                    } 
                } -Content {"Leave"}

                $UsrGrp += @{ GroupName = $newgroup.CommonName; Edit = $lnkremusr}
            }
            New-UDGrid -Title "Member of" -Header @("GroupName", "Edit") -Properties @("GroupName", "Edit") -Endpoint {
                $UsrGrp | Out-UDGridData
            }
        } 
    }
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            $allgrps = (Get-WRADGroup -Reference).ObjectGUID
            $usringrp = (Get-WRADGroupOfUser -Reference -UserObjectGUID $usrguid).GroupObjectGUID

            $filteredgrps = $allgrps | where {$usringrp -notcontains $_}
            $grpforusr = @()
            ForEach($Group in $filteredgrps){
                $tg = Get-WRADGroup -Reference -ObjectGUID $Group
                $lnkremusr = New-UDElement -Tag "a" -Attributes @{
                    className = "btn"
                    target = "_self"
                    href = "$usrguid"
                    onClick = {
                        #Remove selected Group from Group
                        New-WRADGroupOfUser -Reference -UserObjectGUID $usrguid -GroupObjectGUID $tg.ObjectGUID
                        Write-WRADLog -logtext "Added User $UsrUN to Group $($tg.CommonName)" -level 0
                    } 
                } -Content {"Add"}

                $grpforusr += @{CommonName = $tg.CommonName; CreatedDate = $tg.CreatedDate; Edit = $lnkremusr}
            }

            New-UDGrid -Title "Add $($Script:EUuser.DisplayName) to Group" -Header @("CommonName", "Create date", "Edit") -Properties @("CommonName", "CreatedDate", "Edit") -Endpoint {
                $grpforusr | Out-UDGridData
            }
        }
    } 
}