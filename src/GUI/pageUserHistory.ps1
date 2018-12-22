#History of User
$PageUserHistory = New-UDPage -Name "User History" -AuthorizedRole @("WRADadmin","Auditor") -AutoRefresh -RefreshInterval 30 -Content {
    #Show User
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            #List All User
<<<<<<< HEAD
            New-UDGrid -Title "All user" -Header @("Username", "Displayname", "Create date", "Enabled", "History") -Properties @("Username", "DisplayName", "CreatedDate", "Enabled", "History") -Endpoint {
=======
            New-UDGrid -Title "All user" -Header @("Username", "Displayname", "Create date", "Enabled", "Edit") -Properties @("Username", "DisplayName", "CreatedDate", "Enabled", "Edit") -Endpoint {
>>>>>>> 6581f3e577d4a41c3d8c8e039f5dde8d03cd2c79
                
                $Global:WRADDBConnection = $ArgumentList[0].dbconnection

                $AllUserGrid = @()
                $AllUser = Get-WRADUser

                ForEach($User in $AllUser){
<<<<<<< HEAD
                    $AllUserGrid += @{Username = $User.UserPrincipalName; DisplayName = $User.DisplayName; Enabled = $User.Enabled; History =(New-UDLink -Text "History" -Url "/UserHistory/$($User.ObjectGUID)")} 
=======
                    $AllUserGrid += @{Username = $User.UserPrincipalName; DisplayName = $User.DisplayName; Enabled = $User.Enabled; Edit =(New-UDLink -Text "History" -Url "/UserHistory/$($User.ObjectGUID)")} 
>>>>>>> 6581f3e577d4a41c3d8c8e039f5dde8d03cd2c79
                }
                
                $AllUserGrid | Out-UDGridData
            } -ArgumentList $WRADEndpointVar
        }
    }
}

<<<<<<< HEAD
$PageUserHistoryDetail = New-UDPage -URL "/UserHistory/:usrguid" -ArgumentList $WRADEndpointVar -AuthorizedRole @("WRADadmin","Auditor") -Endpoint {
    param($usrguid)
=======
$PageUserHistoryDyn = New-UDPage -URL "/UserHistory/:usrguid" -ArgumentList $WRADEndpointVar -AuthorizedRole @("WRADadmin","Auditor") -Endpoint {
    param($usrguid)
    #Edit User details with Memberships
>>>>>>> 6581f3e577d4a41c3d8c8e039f5dde8d03cd2c79

    #load-WRADDBCommands
    $Global:WRADDBConnection = $ArgumentList[0].dbconnection
    $Script:Scriptpath = $ArgumentList[0].scrptroot
    $DBConnect = $Global:WRADDBConnection

    load-WRADModules
<<<<<<< HEAD

    #History View of User
    $UserHistory = Get-WRADHistoryOfUser -ObjectGUID $usrguid | Sort-Object -Property VersionEndTime -Descending
    $UserNow = Get-WRADUser -ObjectGUID $usrguid
    New-UDRow {
        New-UDColumn -Size 12 -Content {
            New-UDHTML "<p style='color:white;font-size:1.8em'>History of User $usrguid</p>"
        }
    }
    New-UDRow {
        New-UDColumn -Size 12 -Content {
            New-UDCollapsible -Items {

                $DateFrom = $UserNow.LastModifiedDate |get-Date -format "dd.MM.yyyy HH:mm:ss"
                    $DateTo = "now"
                        New-UDCollapsibleItem -Title "$DateFrom - $DateTo" -Content {
                             New-UDCollection -Content {
                                New-UDCollectionItem -Content { "Username: "+$UserNow.userPrincipalName }
                                New-UDCollectionItem -Content { "SAMAccountName: "+$UserNow.SAMAccountName }
                                New-UDCollectionItem -Content { "Display Name: "+$UserNow.DisplayName }
                                New-UDCollectionItem -Content { "Distinguished Name: "+$UserNow.DistinguishedName }
                                New-UDCollectionItem -Content { "Description: "+$UserNow.Description }
                                New-UDCollectionItem -Content { "Enabled: "+$UserNow.Enabled }
                                New-UDCollectionItem -Content { "Expired: "+$UserNow.Expired }
                            }
                        }

                ForEach($Entry in $UserHistory){
                    $DateFrom = $Entry.VersionStartTime |get-Date -format "dd.MM.yyyy HH:mm:ss"
                    $DateTo = $Entry.VersionEndTime |get-Date -format "dd.MM.yyyy HH:mm:ss"
                    New-UDCollapsibleItem -Title "$DateFrom - $DateTo" -Content {
                         New-UDCollection -Content {
                            New-UDCollectionItem -Content { "Username: "+$Entry.userPrincipalName }
                            New-UDCollectionItem -Content { "SAMAccountName: "+$Entry.SAMAccountName }
                            New-UDCollectionItem -Content { "Display Name: "+$Entry.DisplayName }
                            New-UDCollectionItem -Content { "Distinguished Name: "+$Entry.DistinguishedName }
                            New-UDCollectionItem -Content { "Description: "+$Entry.Description }
                            New-UDCollectionItem -Content { "Enabled: "+$Entry.Enabled }
                            New-UDCollectionItem -Content { "Expired: "+$Entry.Expired }
                            New-UDCollectionItem -Content { "OperationType: "+$Entry.OperationType }
                        }
                    }
                }
            }
        }
    }
        
=======
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
>>>>>>> 6581f3e577d4a41c3d8c8e039f5dde8d03cd2c79
}