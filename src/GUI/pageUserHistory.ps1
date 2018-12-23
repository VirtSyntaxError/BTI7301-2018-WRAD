#History of User
$PageUserHistory = New-UDPage -Name "User History" -AuthorizedRole @("WRADadmin","Auditor","DepLead") -AutoRefresh -RefreshInterval 30 -Content {
    #Show User
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            
            #List All User
            New-UDGrid -Title "All user" -Header @("Username", "Displayname", "Create date", "Enabled", "History") -Properties @("Username", "DisplayName", "CreatedDate", "Enabled", "History") -Endpoint {
                
                $AllUserGrid = @()
                $AllUser = Get-WRADUser

                ForEach($User in $AllUser){
                    $AllUserGrid += @{Username = $User.UserPrincipalName; DisplayName = $User.DisplayName; CreatedDate = ($User.CreatedDate |get-Date -format "dd.MM.yyyy HH:mm:ss"); Enabled = $User.Enabled; History =(New-UDLink -Text "History" -Url "/UserHistory/$($User.ObjectGUID)")} 
                }
                
                $AllUserGrid | Out-UDGridData
            } -ArgumentList $WRADEndpointVar
        }
    }
}

$PageUserHistoryDetail = New-UDPage -URL "/UserHistory/:usrguid" -ArgumentList $WRADEndpointVar -AuthorizedRole @("WRADadmin","Auditor","DepLead") -Endpoint {
    param($usrguid)

    #load-WRADDBCommands
    $Script:Scriptpath = $ArgumentList[0].scrptroot

    load-WRADModules

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
}