#History of User
$PageUserHistory = New-UDPage -Name "User History" -AuthorizedRole @("WRADadmin","Auditor") -AutoRefresh -RefreshInterval 30 -Content {
    #Show User
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            #List All User
            New-UDGrid -Title "All user" -Header @("Username", "Displayname", "Create date", "Enabled", "Edit") -Properties @("Username", "DisplayName", "CreatedDate", "Enabled", "Edit") -Endpoint {
                
                $Global:WRADDBConnection = $ArgumentList[0].dbconnection

                $AllUserGrid = @()
                $AllUser = Get-WRADUser

                ForEach($User in $AllUser){
                    $AllUserGrid += @{Username = $User.UserPrincipalName; DisplayName = $User.DisplayName; Enabled = $User.Enabled; Edit =(New-UDLink -Text "History" -Url "/UserHistory/$($User.ObjectGUID)")} 
                }
                
                $AllUserGrid | Out-UDGridData
            } -ArgumentList $WRADEndpointVar
        }
    }
}

$PageUserHistoryDyn = New-UDPage -URL "/UserHistory/:usrguid" -ArgumentList $WRADEndpointVar -AuthorizedRole @("WRADadmin","Auditor") -Endpoint {
    param($usrguid)
    #Edit User details with Memberships

    #load-WRADDBCommands
    $Global:WRADDBConnection = $ArgumentList[0].dbconnection
    $Script:Scriptpath = $ArgumentList[0].scrptroot
    $DBConnect = $Global:WRADDBConnection

    load-WRADModules
    enable-WRADLogging
    
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #Detailed View of User
            $Script:EUuser = Get-WRADUser -ObjectGUID $usrguid
  
            if($Script:EUuser.Enabled){
                $EUenabled = "Yes"
            } else {
                $EUenabled = "No"
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
                        if([string]::IsNullOrEmpty($Global:WRADDBConnection)){
                            $Global:WRADDBConnection = $DBConnect
                        }

                        Remove-WRADGroupOfUser -Reference -UserObjectGUID $usrguid -GroupObjectGUID $newgroup.ObjectGUID
                        Write-WRADLog -logtext "Removed User $usrguid from Group $($newgroup.CommonName)" -level 0
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
                        if([string]::IsNullOrEmpty($Global:WRADDBConnection)){
                            $Global:WRADDBConnection = $DBConnect
                        }

                        New-WRADGroupOfUser -Reference -UserObjectGUID $usrguid -GroupObjectGUID $tg.ObjectGUID
                        Write-WRADLog -logtext "Added User $usrguid to Group $($tg.CommonName)" -level 0
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