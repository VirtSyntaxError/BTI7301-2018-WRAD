#Edit Group
$PageEditGroup = New-UDPage -Name "Edit Group" -AuthorizedRole @("WRADadmin","Auditor") -AutoRefresh -RefreshInterval 30 -Content {
    
    New-UDRow {
        New-UDColumn -Size 3 -Content {

        }
        New-UDColumn -Size 6 -Content {
            New-UDGrid -Title "All user" -Header @("CommonName", "Create date", "Edit") -Properties @("CommonName", "CreatedDate", "Edit") -Endpoint {
                
                $Global:WRADDBConnection = $ArgumentList[0].dbconnection

                $AllGroupGrid = @()
                $AllGroups = Get-WRADGroup -Reference
                ForEach($Group in $AllGroups){
                    $AllGroupGrid += @{CommonName = $Group.CommonName; CreatedDate = $User.CreatedDate;  Edit =(New-UDLink -Text "Edit" -Url "/EditGroup/$($Group.ObjectGUID)")} 
                }

                $AllGroupGrid | Out-UDGridData
            } -ArgumentList $WRADEndpointVar
        }
    }
}

$AllGrpFGrp = @();
$AllGrpFUsr = @();
$PageEditGroupDyn = New-UDPage -Id "PageEditGroupDyn" -URL "/EditGroup/:grpguid" -ArgumentList $WRADEndpointVar -AuthorizedRole @("WRADadmin","Auditor") -Endpoint {
	param($grpguid)

    $Global:WRADDBConnection = $ArgumentList[0].dbconnection
    $DBConnect = $Global:WRADDBConnection
    $Script:Scriptpath = $ArgumentList[0].scrptroot

    load-WRADDBCommands

	$Script:EGgroup = Get-WRADGroup -Reference -ObjectGUID $grpguid

	New-UDRow {
		New-UDColumn -Size 6 -Content {
			New-UDInput -Title "Edit Group" -Id "FormEditGroup" -Content {
                New-UDInputField -Type 'textbox' -Name 'egcn' -Placeholder 'Common Name' -DefaultValue $Script:EGgroup.CommonName
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
                    Update-WRADGroup -Reference -ObjectGUID $grpguid -CommonName $egcn -GroupType $eggrptyp -GRoupTypeSecurity $eggrptypsec

                    New-UDInputAction -Toast "The Group '$egcn' is edited." -Duration 5000
				}
			}
		}
        
		New-UDColumn -Size 6 -Content {
            #Selected group is Member of
			$grpchldgrp = Get-WRADGroupOfGroup -Reference -ChildGroupObjectGUID $grpguid
            
            Write-UDLog -Level Warning -Message "Group $grpguid is Memeber in $($($grpchldgrp).Count) Groups"

            $allpgrps = @()
            ForEach($group in $grpchldgrp){
                $tg = Get-WRADGroup -Reference -ObjectGUID $group.ParentGroupObjectGUID

                $lnkremprntgrp = New-UDElement -Tag "a" -Attributes @{
                    className = "btn"
                    target = "_self"
                    href = "$grpguid"
                    onClick = {
                        #Remove selected Group from Group
                        if([string]::IsNullOrEmpty($Global:WRADDBConnection)){
                            $Global:WRADDBConnection = $DBConnect
                        }

                        Write-UDLog -Level Warning -Message "Remove Gorup $grpguid from Group $($tg.ObjectGUID)"
                        Remove-WRADGroupOfGroup -Reference -ChildGroupObjectGUID $grpguid -ParentGroupObjectGUID $tg.ObjectGUID
                    } 
                } -Content {"Leave"}

                $allpgrps += @{CommonName = $tg.CommonName; CreateDate = $group.CreatedDate; Edit = $lnkremprntgrp}
            }

			New-UDGrid -Title "$($Script:EGgroup.CommonName) is Member of" -Header @("CommonName", "Create date", "Edit") -Properties @("CommonName", "CreateDate", "Edit") -Endpoint {
                $allpgrps | Out-UDGridData
            }
		}
	}
	New-UDRow {
		New-UDColumn -Size 6 -Content {
            #Groups in selcted Group
			$grpprntgrp = Get-WRADGroupOfGroup -Reference -ParentGroupObjectGUID $grpguid 
            
            Write-UDLog -Level Warning -Message "Group $grpguid has $($($grpprntgrp).Count) Childgroups"

            $allcgrps = @()
            ForEach($group in $grpprntgrp){
                $tg = Get-WRADGroup -Reference -ObjectGUID $group.ChildGroupObjectGUID

                $lnkremchldgrp = New-UDElement -Tag "a" -Attributes @{
                    className = "btn"
                    target = "_self"
                    href = "$grpguid"
                    onClick = {
                        #Remove selected Group from Group
                        if([string]::IsNullOrEmpty($Global:WRADDBConnection)){
                            $Global:WRADDBConnection = $DBConnect
                        }

                        Write-UDLog -Level Warning -Message "Remove Group $($tg.ObjectGUID) from Group $grpguid"
                        Remove-WRADGroupOfGroup -Reference -ChildGroupObjectGUID $tg.ObjectGUID -ParentGroupObjectGUID $grpguid
                    } 
                } -Content {"Remove"}

                $allcgrps += @{CommonName = $tg.CommonName; CreateDate = $group.CreatedDate; Edit = $lnkremchldgrp}#(New-UDLink -Text "Remove" -URL "/RemGrpofGrp/$($grpguid )/$($group.ChildGroupObjectGUID)")}
            }

			New-UDGrid -Title "Groups in $($Script:EGgroup.CommonName)" -Header @("CommonName", "Create date", "Edit") -Properties @("CommonName", "CreateDate", "Edit") -Endpoint {
                $allcgrps | Out-UDGridData
            }
		}

        New-UDColumn -Size 6 -Content {
            #User in Group
			$grpfusr = Get-WRADGroupOfUser -Reference -GroupObjectGUID $grpguid
            Write-UDLog -Level Warning -Message "There are $(($grpfusr).Count) Useres in the Group $($Script:EGgroup.CommonName)."
			$AllGrpFUsr = @()
            ForEach($user in $grpfusr){
				$UsrInGrp = Get-WRADUser -Reference -ObjectGUID ($user).UserObjectGUID

				if($UsrInGrp.Enabled){
					$nbld = "Yes";
				} else {
					$nbld = "No";
				}
                
                #Remove User from Group
                $lnkremusr = New-UDElement -Tag "a" -Attributes @{
                    className = "btn"
                    target = "_self"
                    href = "$grpguid"
                    onClick = {
                        #Remove User from selected
                        if([string]::IsNullOrEmpty($Global:WRADDBConnection)){
                            $Global:WRADDBConnection = $DBConnect
                        }

                        Write-UDLog -Level Warning -Message "Remove User $($UsrInGrp.ObjectGUID) from Group $grpguid"
                        Remove-WRADGroupOfUser -Reference -UserObjectGUID $($UsrInGrp.ObjectGUID) -GroupObjectGUID $grpguid
                    } 
                } -Content {"Remove"}

				$AllGrpFUsr += @{Username = $UsrInGrp.UserName; DisplayName = $UsrInGrp.DisplayName; Enabled = $nbld; Edit = $lnkremusr}
			}
			New-UDGrid -Title "User in $($Script:EGgroup.CommonName)" -Header @("Username", "DisplayName", "Enabled", "Edit") -Properties @("Username", "DisplayName", "Enabled", "Edit") -Endpoint {
                $AllGrpFUsr | Out-UDGridData
            }
		}
	}
    New-UDRow {
        New-UDColumn -Size 6 -Content {
            #Add Group to Group
            $allgrpsguid = (Get-WRADGroup -Reference).ObjectGUID
            $childgrpsguid = (Get-WRADGroupOfGroup -Reference -ParentGroupObjectGUID $grpguid).ChildGroupObjectGUID
                
            #Remove already linked groups
            $allgrpguidfilteredtemp = $allgrpsguid | where {$childgrpsguid -notcontains $_}
            $allgrpguidfiltered = $allgrpguidfilteredtemp | where {$grpguid -notcontains $_}
              
            #Create Display-Data
            $allgrps = @()
            ForEach($group in $allgrpguidfiltered) {
                $tg = Get-WRADGroup -Reference -ObjectGUID $group

                $lnkaddgrp = New-UDElement -Tag "a" -Attributes @{
                    className = "btn"
                    target = "_self"
                    href = "$grpguid"
                    onClick = {
                        #Add Group to selected Group
                        if([string]::IsNullOrEmpty($Global:WRADDBConnection)){
                            $Global:WRADDBConnection = $DBConnect
                        }

                        Write-UDLog -Level Warning -Message "Add Group $group to Group $grpguid"
                        New-WRADGroupOfGroup -Reference -ChildGroupObjectGUID $group -ParentGroupObjectGUID $grpguid
                    } 
                } -Content {"Add"}

                $allgrps += @{CommonName = $tg.CommonName; CreatedDate = $tg.CreatedDate; Add = $lnkaddgrp}
            }
             
            #Display remaining groups
            New-UDGrid -Title "Add Groups to $($Script:EGgroup.CommonName)" -Header @("CommonName", "Create date", "Edit") -Properties @("CommonName", "CreatedDate", "Add") -Endpoint {
                $allgrps | Out-UDGridData
            } 
        } 
        New-UDColumn -Size 6 -Content {
            #Add User to Group
            $allusrguid = (Get-WRADUser -Reference).ObjectGUID
            $childusrguid = (Get-WRADGroupOfUser -Reference -GroupObjectGUID $grpguid).UserObjectGUID
             
            #Remove already linked User
            $allusrguidfiltered = $allusrguid | where {$childusrguid -notcontains $_}
            
            #Create used data
            $allusrs = @()
            ForEach($usr in $allusrguidfiltered){
                $tu = Get-WRADUser -Reference -ObjectGUID $usr

                $lnkaddusr = New-UDElement -Tag "a" -Attributes @{
                    className = "btn"
                    target = "_self"
                    href = "$grpguid"
                    onClick = {
                        #Add User to Group
                        if([string]::IsNullOrEmpty($Global:WRADDBConnection)){
                            $Global:WRADDBConnection = $DBConnect
                        }

                        Write-UDLog -Level Warning -Message "Add User $usr to Group $grpguid"
                        New-WRADGroupOfUser -Reference -UserObjectGUID $usr -GroupObjectGUID $grpguid
                    } 
                } -Content {"Add"}

                $allusrs += @{UserName = $tu.Username; DisplayName = $tu.DisplayName; Add = $lnkaddusr}
            }
            
            #Display remaining groups
            New-UDGrid -Title "Add Users to $($Script:EGgroup.CommonName)" -Header @("Username", "Displayname", "Edit") -Properties @("UserName", "DisplayName", "Add") -Endpoint {
                $allusrs | Out-UDGridData
            }
        }
    }
}