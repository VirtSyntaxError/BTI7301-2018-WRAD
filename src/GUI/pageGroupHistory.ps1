#History of Group
$PageGroupHistory = New-UDPage -Name "Group History" -AuthorizedRole @("WRADadmin","Auditor","DepLead") -AutoRefresh -RefreshInterval 30 -Content {
    #Show Group
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            #List All User
            New-UDGrid -Title "All user" -Header @("Groupname", "Group Type", "Create date", "History") -Properties @("Groupname", "GroupType", "CreatedDate", "History") -Endpoint {
                
                $Global:WRADDBConnection = $ArgumentList[0].dbconnection

                $AllGroupGrid = @()
                $AllGroup = Get-WRADGroup

                ForEach($Group in $AllGroup){
                    $AllGroupGrid += @{Groupname = $Group.CommonName; GroupType = $Group.GroupType; CreatedDate = ($Group.CreatedDate |get-Date -format "dd.MM.yyyy HH:mm:ss"); History =(New-UDLink -Text "History" -Url "/GroupHistory/$($Group.ObjectGUID)")} 
                }
                
                $AllGroupGrid | Out-UDGridData
            } -ArgumentList $WRADEndpointVar
        }
    }
}

$PageGroupHistoryDetail = New-UDPage -URL "/GroupHistory/:grpguid" -ArgumentList $WRADEndpointVar -AuthorizedRole @("WRADadmin","Auditor","DepLead") -Endpoint {
    param($grpguid)

    #load-WRADDBCommands
    $Global:WRADDBConnection = $ArgumentList[0].dbconnection
    $Script:Scriptpath = $ArgumentList[0].scrptroot
    $DBConnect = $Global:WRADDBConnection

    load-WRADModules

    #History View of Group
    $GroupHistory = Get-WRADHistoryOfGroup -ObjectGUID $grpguid | Sort-Object -Property VersionEndTime -Descending
    $GroupNow = Get-WRADGroup -ObjectGUID $grpguid
    New-UDRow {
        New-UDColumn -Size 12 -Content {
            New-UDHTML "<p style='color:white;font-size:1.8em'>History of Group $grpguid</p>"
        }
    }
    New-UDRow {
        New-UDColumn -Size 12 -Content {
            New-UDCollapsible -Items {
                
                $DateFrom = $GroupNow.LastModifiedDate |get-Date -format "dd.MM.yyyy HH:mm:ss"
                $DateTo = "now"
                    New-UDCollapsibleItem -Title "$DateFrom - $DateTo" -Content {
                         New-UDCollection -Content {
                            New-UDCollectionItem -Content { "Groupname: "+$GroupNow.CommonName }
                            New-UDCollectionItem -Content { "SAMAccountName: "+$GroupNow.SAMAccountName }
                            New-UDCollectionItem -Content { "Distinguished Name: "+$GroupNow.DistinguishedName }
                            New-UDCollectionItem -Content { "Description: "+$GroupNow.Description }
                            New-UDCollectionItem -Content { "Group Type: "+$GroupNow.GroupType }
                            New-UDCollectionItem -Content { "Group Type Security: "+$GroupNow.GroupTypeSecurity }
                        }
                    }

                ForEach($Entry in $GroupHistory){
                    $DateFrom = $Entry.VersionStartTime |get-Date -format "dd.MM.yyyy HH:mm:ss"
                    $DateTo = $Entry.VersionEndTime |get-Date -format "dd.MM.yyyy HH:mm:ss"
                    New-UDCollapsibleItem -Title "$DateFrom - $DateTo" -Content {
                         New-UDCollection -Content {
                            New-UDCollectionItem -Content { "Groupname: "+$Entry.CommonName }
                            New-UDCollectionItem -Content { "SAMAccountName: "+$Entry.SAMAccountName }
                            New-UDCollectionItem -Content { "Distinguished Name: "+$Entry.DistinguishedName }
                            New-UDCollectionItem -Content { "Description: "+$Entry.Description }
                            New-UDCollectionItem -Content { "Group Type: "+$Entry.GroupType }
                            New-UDCollectionItem -Content { "Group Type Security: "+$Entry.GroupTypeSecurity }
                            New-UDCollectionItem -Content { "OperationType: "+$Entry.OperationType }
                        }
                    }
                }
            }
        }
    }
}