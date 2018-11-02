Set-StrictMode -Version Latest

$null = [System.Reflection.Assembly]::LoadWithPartialName('MySql.Data')
$BuiltinParameters = @("ErrorAction","WarningAction","Verbose","ErrorVariable","WarningVariable","OutVariable","OutBuffer","Debug","Reference","NoObjectGUID","ExistentObjectGUID","UserPrincipalNameNoDomain")

function Connect-WRADDatabase {
    begin
	{
        $PasswordPlain = "ktX4xRb7qxSw6oPctx"
        $Password = ConvertTo-SecureString -AsPlainText $PasswordPlain -Force
        $Username = "wradadmin"
        $Server = "localhost"
        $Port = "3306"
        $Database = "WRAD"
        $SSLMode = "none"

        $Credentials =  New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $Username,$Password
        $ConnectionString = "server=$Server;port=$Port;uid=$Username;pwd=$PasswordPlain;database=$Database;SSLMode=$SSLMode"
	}
	Process
	{
		try
		{
    
            [MySql.Data.MySqlClient.MySqlConnection]$Connection = New-Object MySql.Data.MySqlClient.MySqlConnection($ConnectionString)

            $Global:WRADDBConnection = $Connection

            Write-Verbose "Connecting to Database";
            $Connection.Open()
        }
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}

    <#
    .SYNOPSIS

    Connect to WRAD Database.

    .DESCRIPTION

    Connects to localhost and selects the WRAD Database.

    .INPUTS

    None. You cannot pipe objects to Connect-WRADDatabase.

    .OUTPUTS

    Sets the current connection in a global variable named WRADDBConnection.

    .EXAMPLE

    C:\PS> Connect-WRADDatabase
    
    #>
}

function Invoke-MariaDBQuery {
	Param
	(
        [Parameter()]
		[ValidateNotNullOrEmpty()]
        [MySql.Data.MySqlClient.MySqlConnection]
		$Connection = $Global:WRADDBConnection,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Query
	)
	begin
	{
	}
	Process
	{
		try
		{
			
			[MySql.Data.MySqlClient.MySqlCommand]$Command = New-Object MySql.Data.MySqlClient.MySqlCommand
			$command.Connection = $Connection
			$command.CommandText = $Query
			[MySql.Data.MySqlClient.MySqlDataAdapter]$Adapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
			$Dataset = New-Object System.Data.DataSet
			$Count = $Adapter.Fill($DataSet)
            Write-Verbose "Executed Query: $Query"
            if ($Query.Contains("SELECT")){
			    Write-Verbose "$Count records found"
            }
			$Dataset.Tables.foreach{$_}
            Write-Verbose "Query succeeded"
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
    <#
    .SYNOPSIS

    Invokes a MariaDB query.

    .DESCRIPTION

    Invokes the given query to the given connection and catches errors.

    .PARAMETER Connection
    Specifies the connection to a database. The global connection is the default.

    .PARAMETER Query
    Specifies the SQL query.

    .INPUTS

    None. You cannot pipe objects to Invoke-MariaDBQuery.

    .OUTPUTS

    System.Row. Invoke-MariaDBQuery returns a row with all parameters from the query.

    .EXAMPLE

    C:\PS> Invoke-MariaDBQuery -Query "SELET * FROM WRADUser"
    System.Row

    .EXAMPLE

    C:\PS> Invoke-MariaDBQuery -Query "SELET * FROM WRADUser" -Connection $Connection
    System.Row
    #>
}

function Get-WRADUser {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="REFERENCE")]
		[ValidateNotNullOrEmpty()]
		[String]$UserName,

        [Parameter(ParameterSetName="ACTUAL")]
		[ValidateNotNullOrEmpty()]
		[string]$SAMAccountName,

        [Parameter(ParameterSetName="ACTUAL")]
		[ValidateNotNullOrEmpty()]
		[string]$UserPrincipalName,

        [Parameter(ParameterSetName="ACTUAL")]
		[ValidateNotNullOrEmpty()]
		[string]$UserPrincipalNameNoDomain,

        [Parameter(ParameterSetName="ACTUAL")]
        [Parameter(ParameterSetName="REFERENCE")]
		[ValidateNotNullOrEmpty()]
		[string]$DisplayName,

        [Parameter(ParameterSetName="ACTUAL")]
        [Parameter(ParameterSetName="REFERENCE")]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID,

        [Parameter(ParameterSetName="ACTUAL")]
        [Parameter(ParameterSetName="REFERENCE")]
		[ValidateNotNullOrEmpty()]
		[Switch]$Disabled,

        [Parameter(ParameterSetName="ACTUAL")]
		[ValidateNotNullOrEmpty()]
		[Switch]$Expired,

        [Parameter(ParameterSetName="REFERENCE")]
		[ValidateNotNullOrEmpty()]
		[Switch]$NoObjectGUID


	)
	begin
	{
        $Table = 'WRADUser'
        if($Reference){
            $Table = 'WRADRefUser'
        }
        $Query = 'SELECT * FROM '+$Table;

        $FirstParameter = $true;

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                $Value = (Get-Variable -Name $_ ).Value

                if($_ -eq "Disabled"){ 
                    $Value = 0 
                    $_ = "Enabled"
                 }
                elseif($_ -eq "Expired"){ 
                    $Value = 1
                }
        
                if($FirstParameter){
                    $Query += ' WHERE `'+$_+'` = "'+$Value+'" '
                    $FirstParameter = $false
                } else {
                    $Query += ' AND `'+$_+'` = "'+$Value+'" '
                }
            }
        }

        if($NoObjectGUID){
            if($FirstParameter){
                $Query += ' WHERE '
                $FirstParameter = $false
            } else {
                $Query += ' AND '
            }
            $Query += '`ObjectGUID` LIKE "noguid%"'
        }    
        if($UserPrincipalNameNoDomain){
            if($FirstParameter){
                $Query += ' WHERE '
                $FirstParameter = $false
            } else {
                $Query += ' AND '
            }
            $Query += '`UserPrincipalName` LIKE "'+$UserPrincipalNameNoDomain+'@%" '
        }
    
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
            Write-Error -Message $_.Exception.Message
			break
		}
	}
    <#
    .SYNOPSIS

    Gets all users.

    .DESCRIPTION

    Gets all users which actually exist in the database. These are the fetched users from the Active Directory.
    The Output does not conaint any deleted users.
    It is possible to load reference users with the -Reference switch.

    .PARAMETER Reference
    Specifies if all reference users should be shown instead of the actual one.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of an user. Only usable with actual users.

    .PARAMETER UserPrincipalName
    Specifies the UserPrincipalName of an user. Only usable with actual users.

    .PARAMETER Username
    Specifies the Username of an user. Only usable with reference users.
    
    .PARAMETER DisplayName
    Specifies the DisplayName of an user.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of an user.

    .PARAMETER Disabled
    Specifies if an user is disabled.

    .PARAMETER Expired
    Specifies if an user is expired. Only usable with actual users.

    .INPUTS

    None. You cannot pipe objects to Get-WRADUser.

    .OUTPUTS

    System.Array. Get-WRADUser returns all parameters from the user table (actual or reference) in an array.

    .EXAMPLE

    C:\PS> Get-WRADUser -Reference -Username furid
    Username           : furid
    DisplayName        : Dario Furigo
    CreatedDate        : 15.10.2018 10:51:00
    Enabled            : True
    Description        : Darios User

    .EXAMPLE

    C:\PS> Get-WRADUser -SAMAccountName furid
    ObjectGUID         : testid
    SAMAccountName     : furid
    DistinguishedName  : CN="dario",CN="example",CN="local"
    LastLogonTimestamp : 
    userPrincipalName  : dario.furigo
    DisplayName        : Dario Furigo
    CreatedDate        : 12.10.2018 08:15:44
    LastModifiedDate   : 12.10.2018 08:26:00
    Enabled            : True
    Description        : Darios User
    Expired            : False

    .EXAMPLE

    C:\PS> Get-WRADUser -Disabled
    ObjectGUID         : testid2
    SAMAccountName     : pidu
    DistinguishedName  : CN="pidu",CN="example",CN="local"
    LastLogonTimestamp : 
    userPrincipalName  : pidu.schaerz
    DisplayName        : Beat Schärz
    CreatedDate        : 12.10.2018 13:22:27
    LastModifiedDate   : 12.10.2018 13:23:38
    Enabled            : False
    Description        : Pidus User
    Expired            : True

    #>

}

function New-WRADUser {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$SAMAccountName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$DistinguishedName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[AllowEmptyString()]
		[Nullable[DateTime]]$LastLogonTimestamp,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$UserPrincipalName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$DisplayName,

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$Username,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Bool]$Enabled,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[AllowEmptyString()]
		[String]$Description,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Expired


	)
	begin
	{
        $Table = ''
        $QueryEnd = ') '
        $QueryMiddle = ' ) VALUES ('
        if($Reference){
            $Table = 'WRADRefUser'
        } else {
            $Table = 'WRADUser'
            if($DistinguishedName){
                $DistinguishedName = $DistinguishedName.Replace('"','&DQ&')
            }
            if($Description){
                $Description = $Description.Replace('"','&DQ&')
            }

            if($LastLogonTimestamp){
                [String]$LastLogonTimestamp = $LastLogonTimestamp.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        $Query = 'INSERT INTO '+$Table+' ('
        $QueryValue = @()
        $QueryVariable = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value

                if($_ -eq "Expired" -or $_ -eq "Enabled"){
                    if($Value -eq $true ){
                        [Int]$Value = 1
                    } else {
                        [Int]$Value = 0
                    }
                } elseif ($_ -ne "LastLogonTimestamp"){
                    $Value = $Value.Replace('&DQ&','\"')
                }

                $QueryVariable += '`'+$_+'`'
                if($_ -eq "LastLogonTimestamp" -and $Value -eq "") {
                    $QueryValue += ' NULL '
                } else {
                    $QueryValue += ' "'+$Value+'"'
                }
            }
        }

        $Query += ($QueryVariable -join ", ")
        $Query += $QueryMiddle
        $Query += ($QueryValue -join ", ")
        $Query += $QueryEnd
	}
	Process
	{
		try
		{
            Write-Verbose "Checking for already existent user";
            if ($Reference) {
                if($ObjectGUID){
                    if((Get-WRADUser -Reference -ObjectGUID $ObjectGUID) -ne $null){
                        $CustomError = "Duplicate entry for ObjectGUID "+$ObjectGUID
                        throw($CustomError) 
                    }
                }
            } else {
                if((Get-WRADUser -ObjectGUID $ObjectGUID) -ne $null){
                    $CustomError = "Duplicate entry for ObjectGUID "+$ObjectGUID
                    throw($CustomError) 
                }
            }
            
			Write-Verbose "Invoking INSERT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
    <#
    .SYNOPSIS

    Creates new user.

    .DESCRIPTION

    Creates new user in the database.

    .PARAMETER Reference
    Specifies if a reference user should be created instead of an actual one.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of the user.

    .PARAMETER UserPrincipalName
    Specifies the UserPrincipalName of the user.

    .PARAMETER DistinguishedName
    Specifies the DistinguishedName of the user. Like CN="testuser",CN="example",CN="local"

    .PARAMETER LastLogonTimestamp
    Specifies the LastLogonTimestamp of the user. This should be a DateTime value.
    
    .PARAMETER DisplayName
    Specifies the DisplayName of the user.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the user.

    .PARAMETER Enabled
    Specifies if the user is enabled.

    .PARAMETER Expired
    Specifies if the user is expired.

    .PARAMETER Description
    Specifies the description.

    .INPUTS

    None. You cannot pipe objects to New-WRADUser.

    .OUTPUTS

    Nothing. New-WRADUser returns an error if something is wrong.

    .EXAMPLE

    C:\PS> New-WRADUser -ObjectGUID d9dl998-03jlasd9-lasd99 -SAMAccountName testuser -DistinguishedName 'CN="testuser",CN="example",CN="local"' -UserPrincipalName test.user -DisplayName "testuser" -Description "Testuser for WRAD" -LastLogonTimestamp $timestamp

    #>
}

function Update-WRADUser {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$SAMAccountName,

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$Username,

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$NewObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$DistinguishedName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[AllowEmptyString()]
		[Nullable[DateTime]]$LastLogonTimestamp,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$UserPrincipalName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$DisplayName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Bool]$Enabled,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[AllowEmptyString()]
		[String]$Description,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Bool]$Expired


	)
	begin
	{
        $Table = ''
        $QueryEnd = ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
        if($Reference){
            $Table = 'WRADRefUser'
        } else {
            $Table = 'WRADUser'
            if($DistinguishedName){
                $DistinguishedName = $DistinguishedName.Replace('"','&DQ&')
            }
            if($Description){
                $Description = $Description.Replace('"','&DQ&')
            }

            if($LastLogonTimestamp){
                [String]$LastLogonTimestamp = $LastLogonTimestamp.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        $Query = 'UPDATE '+$Table+' SET '
        $QueryValue = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_ -and $_ -ne "ObjectGUID") {
                [String]$Value = (Get-Variable -Name $_).Value

                if($_ -eq "Expired" -or $_ -eq "Enabled"){
                    if($Value -eq $true ){
                        [Int]$Value = 1
                    } else {
                        [Int]$Value = 0
                    }
                } elseif ($_ -ne "LastLogonTimestamp"){
                    $Value = $Value.Replace('&DQ&','\"')
                }

                if($_ -eq "NewObjectGUID"){
                    $QueryValue += ' `ObjectGUID` = "'+$NewObjectGUID+'" '
                } else {
                     if($_ -eq "LastLogonTimestamp" -and $Value -eq "") {
                        $QueryValue += ' `'+$_+'` = NULL '
                    } else {
                        $QueryValue += ' `'+$_+'` = "'+$Value+'" '
                    }
                }
            }
        }

        $Query += ($QueryValue -join ", ")
        $Query += $QueryEnd
	}
	Process
	{
        try
		{

            Write-Verbose "Checking if at least one parameter is set";
            if($QueryValue.Count -eq 0){
                $CustomError = "No parameter is set for user with ObjectGUID "+$ObjectGUID
                throw($CustomError) 
            }

            Write-Verbose "Checking for already existent user";
            if($Reference) {
                if((Get-WRADUser -Reference -ObjectGUID $ObjectGUID) -eq $null){
                    $CustomError = "No entry for ObjectGUID "+$ObjectGUID
                    throw($CustomError) 
                }
            } else {
                if((Get-WRADUser -ObjectGUID $ObjectGUID) -eq $null){
                    $CustomError = "No entry for ObjectGUID "+$ObjectGUID
                    throw($CustomError) 
                }
            }

			Write-Verbose "Invoking Update SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
    <#
    .SYNOPSIS

    Updates a user.

    .DESCRIPTION

    Updates a user in the database with the given parameters.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of the user.

    .PARAMETER UserPrincipalName
    Specifies the UserPrincipalName of the user.

    .PARAMETER DistinguishedName
    Specifies the DistinguishedName of the user. Like CN="testuser",CN="example",CN="local"

    .PARAMETER LastLogonTimestamp
    Specifies the LastLogonTimestamp of the user. This should be a DateTime value.
    
    .PARAMETER DisplayName
    Specifies the DisplayName of the user.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the user.

    .PARAMETER Disabled
    Specifies if the user is disabled.

    .PARAMETER Expired
    Specifies if the user is expired.

    .PARAMETER Description
    Specifies the description.

    .INPUTS

    None. You cannot pipe objects to Update-WRADUser.

    .OUTPUTS

    Nothing. Update-WRADUser returns an error if something is wrong.

    .EXAMPLE

    C:\PS> Update-WRADUser -ObjectGUID d9dl998-03jlasd9-lasd99 -SAMAccountName testuser -LastLogonTimestamp $timestamp

    #>
}

function Remove-WRADUser {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID
	)
	begin
	{
        $Table = ''
        $QueryEnd = ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
        if($Reference){
            $Table = 'WRADRefUser'
        } else {
            $Table = 'WRADUser'
        }
        $Query = 'DELETE FROM '+$Table+' '
        $Query += $QueryEnd
	}
	Process
	{
		try
		{
            Write-Verbose "Checking if user exists";
            if($Reference) {
                if((Get-WRADUser -Reference -ObjectGUID $ObjectGUID) -eq $null){
                    $CustomError = "No entry for ObjectGUID "+$ObjectGUID
                    throw($CustomError) 
                }
            } else {
                if((Get-WRADUser -ObjectGUID $ObjectGUID) -eq $null){
                    $CustomError = "No entry for ObjectGUID "+$ObjectGUID
                    throw($CustomError) 
                }
            }

			Write-Verbose "Invoking DELETE SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADGroup {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
    (
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$SAMAccountName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$CommonName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
        [ValidateSet('DomainLocal','Global','Universal')]
		[string]$GroupType,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID,
        
        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateSet('Security','Distribution')]
		[String]$GroupTypeSecurity,

        [Parameter(ParameterSetName="REFERENCE")]
		[ValidateNotNullOrEmpty()]
		[Switch]$NoObjectGUID

	)
	begin
	{
        $Table = 'WRADGroup'
        $QueryEnd = ''
        if($Reference){
            $Table = 'WRADRefGroup'
        }
        $Query = 'SELECT * FROM '+$Table;

        $FirstParameter = $true;

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                $Value = (Get-Variable -Name $_).Value

                if($FirstParameter){
                    $Query += ' WHERE `'+$_+'` = "'+$Value+'" '
                    $FirstParameter = $false
                } else {
                    $Query += ' AND `'+$_+'` = "'+$Value+'" '
                }
            }
        }	
        
        if($NoObjectGUID){
            if($FirstParameter){
                $Query += ' WHERE `ObjectGUID` LIKE "noguid%" '
            } else {
                $Query += ' AND `ObjectGUID` LIKE "noguid%" '
            }
        }

        $Query += $QueryEnd	
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function New-WRADGroup {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$SAMAccountName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$CommonName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$DistinguishedName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
        [ValidateSet('DomainLocal','Global','Universal')]
		[String]$GroupType,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[AllowEmptyString()]
		[String]$Description,
        
        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateSet('Security','Distribution')]
		[String]$GroupTypeSecurity

	)
	begin
	{
        $Table = ''
        $QueryEnd = ') '
        $QueryMiddle = ' ) VALUES ('
        if($Reference){
            $Table = 'WRADRefGroup'
        } else {
            $Table = 'WRADGroup'
            if($DistinguishedName){
                $DistinguishedName = $DistinguishedName.Replace('"','&DQ&')
            }
            if($Description){
                $Description = $Description.Replace('"','&DQ&')
            }
        }
        $Query = 'INSERT INTO '+$Table+' ('
        $QueryValue = @()
        $QueryVariable = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value
                $QueryVariable += '`'+$_+'`'
                $QueryValue += ' "'+$Value+'"'
            }
        }

        $Query += ($QueryVariable -join ", ")
        $Query += $QueryMiddle
        $Query += ($QueryValue -join ", ")
        $Query += $QueryEnd	
	}
	Process
	{
		try
		{
            Write-Verbose "Checking for already existent group";
            if($Reference) {
                if($ObjectGUID){
                    if((Get-WRADGroup -Reference -ObjectGUID $ObjectGUID) -ne $null){
                        $CustomError = "Duplicate entry for ObjectGUID "+$ObjectGUID
                        throw($CustomError) 
                    }
                }
            } else {
                if((Get-WRADGroup -ObjectGUID $ObjectGUID) -ne $null){
                    $CustomError = "Duplicate entry for ObjectGUID "+$ObjectGUID
                    throw($CustomError) 
                }
            }

			Write-Verbose "Invoking INSERT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	<#
    .SYNOPSIS

    Creates a new group.

    .DESCRIPTION

    Creates a new group in the database with the given parameters.

    
    .PARAMETER Reference
    Specifies if a reference group should be created instead of an actual one.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of the group.

    .PARAMETER CommonName
    Specifies the CommonName of the group.

    .PARAMETER DistinguishedName
    Specifies the DistinguishedName of the group. Like CN="testgroup",CN="example",CN="local"

    .PARAMETER GroupType
    Specifies the GroupType of the group. This should be 'DomainLocal','Global' or 'Universal'.
    
    .PARAMETER GroupTypeSecurity
    Specifies the GroupTypeSecurity of the group. This should be either Security' or 'Distribution'.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the group.

    .PARAMETER Description
    Specifies the description.

    .INPUTS

    None. You cannot pipe objects to New-WRADGroup.

    .OUTPUTS

    Nothing. New-WRADGroup returns an error if something is wrong.

    .EXAMPLE

    C:\PS> New-WRADGroup -ObjectGUID d9dl998-03jlasd6-lasd11 -SAMAccountName "Domain Powerusers" -CommonName "Domain Powerusers" -DistinguishedName 'CN="Domain Powerusers",CN="example",CN="local"' -GroupTypeSecurity Security -GroupType DomainLocal

    #>
}

function Update-WRADGroup {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$SAMAccountName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$CommonName,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$DistinguishedName,

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$NewObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
        [ValidateSet('DomainLocal','Global','Universal')]
		[String]$GroupType,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
		[AllowEmptyString()]
		[String]$Description,
        
        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateSet('Security','Distribution')]
		[String]$GroupTypeSecurity


	)
	begin
	{
        $Table = ''
        $QueryEnd = ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
        if($Reference){
            $Table = 'WRADRefGroup'
        } else {
            $Table = 'WRADGroup'
            if($DistinguishedName){
                $DistinguishedName = $DistinguishedName.Replace('"','&DQ&')
            }
            if($Description){
                $Description = $Description.Replace('"','&DQ&')
            }
        }
        $Query = 'UPDATE '+$Table+' SET '
        $QueryValue = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_ -and $_ -ne "ObjectGUID") {          
                if($_ -eq "NewObjectGUID"){
                    $QueryValue += ' `ObjectGUID` = "'+$NewObjectGUID+'" '
                } else {
                    [String]$Value = (Get-Variable -Name $_).Value
                    $QueryValue += ' `'+$_+'` = "'+$Value+'" '
                }
            }
        }

        $Query += ($QueryValue -join ", ")
        $Query += $QueryEnd
	}
	Process
	{
        try
		{

            Write-Verbose "Checking if at least one parameter is set";
            if($QueryValue.Count -eq 0){
                $CustomError = "No parameter is set for group with ObjectGUID "+$ObjectGUID
                throw($CustomError) 
            }

            Write-Verbose "Checking for already existent group";
            if($Reference) {
                if((Get-WRADGroup -Reference -ObjectGUID $ObjectGUID) -eq $null){
                    $CustomError = "No entry for ObjectGUID "+$ObjectGUID
                    throw($CustomError) 
                }
            } else {
                if((Get-WRADGroup -ObjectGUID $ObjectGUID) -eq $null){
                    $CustomError = "No entry for ObjectGUID "+$ObjectGUID
                    throw($CustomError) 
                }
            }
            
			Write-Verbose "Invoking Update SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
    <#
    .SYNOPSIS

    Updates a group.

    .DESCRIPTION

    Updates a group in the database with the given parameters.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of the group.

    .PARAMETER CommonName
    Specifies the CommonName of the group.

    .PARAMETER DistinguishedName
    Specifies the DistinguishedName of the group. Like CN="testgroup",CN="example",CN="local"

    .PARAMETER GroupType
    Specifies the GroupType of the group. This should be 'DomainLocal','Global' or 'Universal'.
    
    .PARAMETER GroupTypeSecurity
    Specifies the GroupTypeSecurity of the group. This should be either Security' or 'Distribution'.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the group.

    .PARAMETER Description
    Specifies the description.

    .INPUTS

    None. You cannot pipe objects to Update-WRADGroup.

    .OUTPUTS

    Nothing. Update-WRADGroup returns an error if something is wrong.

    .EXAMPLE

    C:\PS> Update-WRADGroup -ObjectGUID d9dl998-03jlasd6-lasd11 -CommonName "New Groupname"

    #>
}

function Remove-WRADGroup {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID
	)
	begin
	{
        $Table = ''
        $QueryEnd = ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
        if($Reference){
            $Table = 'WRADRefGroup'
        } else {
            $Table = 'WRADGroup'
        }
        $Query = 'DELETE FROM '+$Table+' '
        $Query += $QueryEnd
	}
	Process
	{
		try
		{
            Write-Verbose "Checking if group exists";
            if($Reference) {
                if((Get-WRADGroup -Reference -ObjectGUID $ObjectGUID) -eq $null){
                    $CustomError = "No entry for ObjectGUID "+$ObjectGUID
                    throw($CustomError) 
                }
            } else {
                if((Get-WRADGroup -ObjectGUID $ObjectGUID) -eq $null){
                    $CustomError = "Group $ObjectGUID does not exist"
                    throw($CustomError) 
                }
            }

			Write-Verbose "Invoking DELETE SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADGroupOfUser {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$ExistentObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$UserObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$GroupObjectGUID
	)
	begin
	{
        $Table = 'WRADUserGroup'
        $QueryEnd = ''
        $Query = 'SELECT * FROM '+$Table;
        $FirstParameter = $true;
        if($Reference){
            $Table = 'WRADRefUserGroup'
            $QueryEnd = ' INNER JOIN WRADRefUser ON WRADRefUserGroup.UserObjectGUID = WRADRefUser.ObjectGUID INNER JOIN WRADRefGroup ON WRADRefUserGroup.GroupObjectGUID = WRADRefGroup.ObjectGUID'
            $Query = 'SELECT WRADRefUser.Username,WRADRefGroup.CommonName,WRADRefUserGroup.CreatedDate FROM '+$Table;

            if($ExistentObjectGUID){
                $QueryEnd += ' WHERE WRADRefUser.ObjectGUID NOT LIKE "noguid%" AND WRADRefGroup.ObjectGUID NOT LIKE "noguid%"'
                $FirstParameter = $false
            }
        }

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                $Value = (Get-Variable -Name $_ ).Value

                if($FirstParameter){
                    $QueryEnd += ' WHERE '
                    $FirstParameter = $false
                } else {
                    $QueryEnd += ' AND '
                }

                $QueryEnd += ' `'+$_+'` = "'+$Value+'" '
            }
        } 
        $Query += $QueryEnd	
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function New-WRADGroupOfUser {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$UserObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$GroupObjectGUID

	)
	begin
	{
        $Table = ''
        $QueryEnd = ') '
        $QueryMiddle = ' ) VALUES ('
        if($Reference){
            $Table = 'WRADRefUserGroup'
        } else {
            $Table = 'WRADUserGroup'
        }
        $Query = 'INSERT INTO '+$Table+' ('
        $QueryValue = @()
        $QueryVariable = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value
                $QueryVariable += '`'+$_+'`'
                $QueryValue += ' "'+$Value+'"'
            }
        }

        $Query += ($QueryVariable -join ", ")
        $Query += $QueryMiddle
        $Query += ($QueryValue -join ", ")
        $Query += $QueryEnd
	}
	Process
	{
		try
		{
            #Check for new reference in both tables (ref and refnew) should be performed!!
            Write-Verbose "Checking for already existent user to group mapping and if user and group exist";
            if ($Reference) {  
                if((Get-WRADUser -Reference -ObjectGUID $UserObjectGUID) -eq $null -or (Get-WRADGroup -Reference -ObjectGUID $GroupObjectGUID) -eq $null){
                    $CustomError = "Either UserObjectGUID "+$UserObjectGUID+" or GroupObjectGUID "+$GroupObjectGUID+" does not exist"
                    throw($CustomError) 
                }

                if ((Get-WRADGroupOfUser -Reference -UserObjectGUID $UserObjectGUID -GroupObjectGUID $GroupObjectGUID) -ne $null){
                    $CustomError = "Duplicate entry for NewUserID "+$NewUserID+" and NewGroupID "+$NewGroupID
                    throw($CustomError)
                }
            } else {
                if((Get-WRADUser -ObjectGUID $UserObjectGUID) -eq $null -or (Get-WRADGroup -ObjectGUID $GroupObjectGUID) -eq $null){
                    $CustomError = "Either UserObjectGUID "+$UserObjectGUID+" or GroupObjectGUID "+$GroupObjectGUID+" does not exist"
                    throw($CustomError) 
                }

                if((Get-WRADGroupOfUser -UserObjectGUID $UserObjectGUID -GroupObjectGUID $GroupObjectGUID) -ne $null){
                    $CustomError = "Duplicate entry for UserObjectGUID "+$UserObjectGUID+" and GroupObjectGUID "+$GroupObjectGUID
                    throw($CustomError) 
                }
            }

            Write-Verbose "Invoking INSERT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Remove-WRADGroupOfUser {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$UserObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$GroupObjectGUID
	)
	begin
	{
        $Table = ''
        if($Reference){
            $Table = 'WRADRefUserGroup'
        } else {
            $Table = 'WRADUserGroup'
        }
        $Query = 'DELETE FROM '+$Table+' WHERE '
        $QueryValue = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value
                $QueryValue += '`'+$_+'` = "'+$Value+'"'
            }
        }

        $Query += ($QueryValue -join " AND ")
	}
	Process
	{
		try
		{
            Write-Verbose "Checking if user is in group";
            if ($Reference) {  
                if ((Get-WRADGroupOfUser -Reference -UserObjectGUID $UserObjectGUID -GroupObjectGUID $GroupObjectGUID) -eq $null){
                    $CustomError = "User with ID "+$UserObjectGUID+" does not belong to Group with ID "+$GroupObjectGUID
                    throw($CustomError)
                }
            } else {
                if((Get-WRADGroupOfUser -UserObjectGUID $UserObjectGUID -GroupObjectGUID $GroupObjectGUID) -eq $null){
                    $CustomError = "User with ID "+$UserObjectGUID+" does not belong to Group with ID "+$GroupObjectGUID
                    throw($CustomError) 
                }
            }

			Write-Verbose "Invoking DELETE SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADGroupOfGroup {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$ExistentObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$ChildGroupObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$false)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$ParentGroupObjectGUID
	)
	begin
	{
        $Table = 'WRADGroupGroup'
        $QueryEnd = ''
        $Query = 'SELECT * FROM '+$Table;
        if($Reference){
            $Table = 'WRADRefGroupGroup'
            $QueryEnd = ' INNER JOIN WRADRefGroup AS cg ON WRADRefGroupGroup.ChildGroupObjectGUID = cg.ObjectGUID INNER JOIN WRADRefGroup AS pg ON WRADRefGroupGroup.ParentGroupObjectGUID = pg.ObjectGUID'
            $Query = 'SELECT cg.CommonName AS ChildGroup,pg.CommonName AS ParentGroup,WRADRefGroupGroup.CreatedDate FROM '+$Table;
  
            if($ExistentObjectGUID){
                $QueryEnd += ' WHERE cg.ObjectGUID NOT LIKE "noguid%" AND pg.ObjectGUID NOT LIKE "noguid%"'
                $FirstParameter = $false
            }
        }
        
        $FirstParameter = $true;

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                $Value = (Get-Variable -Name $_ ).Value
        
                if($FirstParameter){
                    $QueryEnd += ' WHERE '
                    $FirstParameter = $false
                } else {
                    $QueryEnd += ' AND '
                }
                $QueryEnd += ' `'+$_+'` = "'+$Value+'" '
            }
        } 
        $Query += $QueryEnd	
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function New-WRADGroupOfGroup {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ChildGroupObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateScript({if($ChildGroupObjectGUID -ne $_ ){ $true } else { throw("ChildGroupObjectGUID cannot be the same as ParentGroupObjectGUID")}})]
		[String]$ParentGroupObjectGUID
	)
	begin
	{
        $Table = ''
        $QueryEnd = ') '
        $QueryMiddle = ' ) VALUES ('
        if($Reference){
            $Table = 'WRADRefGroupGroup'
        } else {
            $Table = 'WRADGroupGroup'
        }
        $Query = 'INSERT INTO '+$Table+' ('
        $QueryValue = @()
        $QueryVariable = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value
                $QueryVariable += '`'+$_+'`'
                $QueryValue += ' "'+$Value+'"'
            }
        }

        $Query += ($QueryVariable -join ", ")
        $Query += $QueryMiddle
        $Query += ($QueryValue -join ", ")
        $Query += $QueryEnd
	}
	Process
	{
		try
		{
            #Check for new reference in both tables (ref and refnew) should be performed!!
            Write-Verbose "Checking for already existent group to group mapping and if groups exist";
            if ($Reference) { 
                 if((Get-WRADGroup -Reference -ObjectGUID $ChildGroupObjectGUID) -eq $null -or (Get-WRADGroup -Reference -ObjectGUID $ParentGroupObjectGUID) -eq $null){
                    $CustomError = "Either ChildGroupObjectGUID "+$ChildGroupObjectGUID+" or ParentGroupObjectGUID "+$ParentGroupObjectGUID+" does not exist"
                    throw($CustomError) 
                }
             
                if ((Get-WRADGroupOfGroup -Reference -ChildGroupObjectGUID $ChildGroupObjectGUID -ParentGroupObjectGUID $ParentGroupObjectGUID) -ne $null){
                    $CustomError = "Duplicate entry for ChildGroupObjectGUID "+$ChildGroupObjectGUID+" and ParentGroupObjectGUID "+$ParentGroupObjectGUID
                    throw($CustomError)
                }
            } else {
                if((Get-WRADGroup -ObjectGUID $ChildGroupObjectGUID) -eq $null -or (Get-WRADGroup -ObjectGUID $ParentGroupObjectGUID) -eq $null){
                    $CustomError = "Either ChildGroupObjectGUID "+$ChildGroupObjectGUID+" or ParentGroupObjectGUID "+$ParentGroupObjectGUID+" does not exist"
                    throw($CustomError) 
                }

                if((Get-WRADGroupOfGroup -ChildGroupObjectGUID $ChildGroupObjectGUID -ParentGroupObjectGUID $ParentGroupObjectGUID) -ne $null){
                    $CustomError = "Duplicate entry for ChildGroupObjectGUID "+$ChildGroupObjectGUID+" and ParentGroupObjectGUID "+$ParentGroupObjectGUID
                    throw($CustomError) 
                }
            }
            
			Write-Verbose "Invoking INSERT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Remove-WRADGroupOfGroup {
    [CmdletBinding(DefaultParameterSetName="ACTUAL")]
    Param
	(
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Reference,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ChildGroupObjectGUID,

        [Parameter(ParameterSetName="ACTUAL", Mandatory=$true)]
        [Parameter(ParameterSetName="REFERENCE", Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ParentGroupObjectGUID
	)
	begin
	{
        $Table = ''
        if($Reference){
            $Table = 'WRADRefGroupGroup'
        } else {
            $Table = 'WRADGroupGroup'
        }
        $Query = 'DELETE FROM '+$Table+' WHERE '
        $QueryValue = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value
                $QueryValue += '`'+$_+'` = "'+$Value+'"'
            }
        }

        $Query += ($QueryValue -join " AND ")
	}
	Process
	{
		try
		{
            Write-Verbose "Checking if group is in group";
            if ($Reference) {  
                if ((Get-WRADGroupOfGroup -Reference -ChildGroupObjectGUID $ChildGroupObjectGUID -ParentGroupObjectGUID $ParentGroupObjectGUID) -eq $null){
                    $CustomError = "Group with ID "+$ChildGroupObjectGUID+" does not belong to Group with ID "+$ParentGroupObjectGUID
                    throw($CustomError)
                }
            } else {
                if((Get-WRADGroupOfGroup -ChildGroupObjectGUID $ChildGroupObjectGUID -ParentGroupObjectGUID $ParentGroupObjectGUID) -eq $null){
                    $CustomError = "Group with ID "+$ChildGroupObjectGUID+" does not belong to Group with ID "+$ParentGroupObjectGUID
                    throw($CustomError) 
                }
            }

			Write-Verbose "Invoking DELETE SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADHistoryOfUser {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID
	)
	begin
	{
        $Query = 'SELECT * FROM WRADUserArchive WHERE `ObjectGUID` = "'+$ObjectGUID+'"';		
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on WRADUserArchive";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADHistoryOfGroup {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID
	)
	begin
	{
        $Query = 'SELECT * FROM WRADGroupArchive WHERE `ObjectGUID` = "'+$ObjectGUID+'"';		
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADGroupArchive";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADDeletedUser {
    Param
	(
	)
	begin
	{
        $Query = 'SELECT * FROM WRADUserArchive WHERE `OperationType` = "d"';		
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADUserArchive";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADDeletedGroup {
    Param
	(
	)
	begin
	{
        $Query = 'SELECT * FROM WRADGroupArchive WHERE `OperationType` = "d"';		
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADGroupArchive";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADDeletedGroupOfUser {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID
	)
	begin
	{
        $Query = 'SELECT * FROM WRADUserGroupArchive WHERE `UserObjectGUID` = "'+$ObjectGUID+'"';		
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADUserGroupArchive";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADDeletedGroupOfGroup {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID
	)
	begin
	{
        $Query = 'SELECT * FROM WRADGroupGroupArchive WHERE `ChildGroupObjectGUID` = "'+$ObjectGUID+'"';		
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADGroupGroupArchive";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADSetting {
    Param
	(
        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$SettingName
	)
	begin
	{
        $Table = 'WRADSetting'
        $Query = 'SELECT * FROM '+$Table;	
        
        if($SettingName) {
            $Query += ' WHERE `SettingName` = "'+$SettingName+'"'
        }	
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Update-WRADSetting {
    Param
	(
        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$ADRoleDepartmentLead,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$ADRoleAuditor,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$ADRoleSysAdmin,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$ADRoleApplOwner,

        [Parameter(Mandatory=$false)]
		[ValidateSet('none','syslog','file')]
		[String]$LogExternal,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$LogFilePath,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$LogSyslogServer,

        [Parameter(Mandatory=$false)]
		[ValidateSet('udp','tcp')]
		[String]$LogSyslogServerProtocol,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$SearchBase
	)
	begin
	{
        $Table = 'WRADSetting'
        $Query = 'UPDATE '+$Table+' SET `SettingValue` = CASE ';
        $Settings = @()
        if($SearchBase){
            $SearchBase = $SearchBase.Replace('"','&DQ&')
        }
        if($LogFilePath){
            $LogFilePath = $LogFilePath.Replace('\','&BS&')
        }
        if($ADRoleDepartmentLead){
            $ADRoleDepartmentLead = $ADRoleDepartmentLead.Replace('"','&DQ&')
        }
        if($ADRoleAuditor){
            $ADRoleAuditor = $ADRoleAuditor.Replace('\','&BS&')
        }
        if($ADRoleSysAdmin){
            $ADRoleSysAdmin = $ADRoleSysAdmin.Replace('"','&DQ&')
        }
        if($ADRoleApplOwner){
            $ADRoleApplOwner = $ADRoleApplOwner.Replace('\','&BS&')
        }

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                $Value = (Get-Variable -Name $_).Value

                $Query += ' WHEN `SettingName` = "'+$_+'" THEN "'+$Value.Replace('&DQ&','\"').Replace('&BS&','\\')+'" '
                $Settings += '"'+$_+'"'
            }
        }		
        $Query += ' END WHERE `SettingName` IN ('+($Settings -join ", ")+' )'
	}
	Process
	{
		try
		{
            Write-Verbose "Checking if at least one parameter is set";
            if($Settings.Count -eq 0){
                $CustomError = "At least one parameter should be specififed!"
                throw($CustomError) 
            }
			Write-Verbose "Invoking Update SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADLog {
    Param
	(
        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Int]$LogSeverity
	)
	begin
	{
        $Query = 'SELECT * FROM WRADLog';	
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADLog";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function New-WRADLog {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Int]$LogSeverity,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$LogText

	)
	begin
	{
        $Query = 'INSERT INTO WRADLog (`LogSeverity`, `LogText`, `LogTimestamp`) VALUES ('+$LogSeverity+', "'+$LogText+'", UTC_TIMESTAMP())';	
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking INSERT SQL Query on table WRADLog";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADExcludedUser {
    Param
	(
        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID
	)
	begin
	{
        $Table = 'WRADExcludeUser'
        $Query = 'SELECT * FROM '+$Table
        
        if($ObjectGUID) {
            $Query += ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"';    
        }
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
            Write-Error -Message $_.Exception.Message
			break
		}
	}
}

function New-WRADExcludedUser {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID
	)
	begin
	{
        $Table = 'WRADExcludeUser'
        $QueryEnd = ') '
        $QueryMiddle = ' ) VALUES ('
        $Query = 'INSERT INTO '+$Table+' ('
        $QueryValue = @()
        $QueryVariable = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value
                $QueryVariable += '`'+$_+'`'
                $QueryValue += ' "'+$Value+'"'
            }
        }

        $Query += ($QueryVariable -join ", ")
        $Query += $QueryMiddle
        $Query += ($QueryValue -join ", ")
        $Query += $QueryEnd
	}
	Process
	{
		try
		{
            Write-Verbose "Checking for existent user";
            if((Get-WRADUser -ObjectGUID $ObjectGUID) -eq $null){
                $CustomError = "User with ObjectGUID "+$ObjectGUID+" does not exist"
                throw($CustomError) 
            }

            if ((Get-WRADExcludedUser -ObjectGUID $ObjectGUID) -ne $null){
                $CustomError = "Duplicate entry for user with ObjectGUID "+$ObjectGUID
                throw($CustomError)
            }

            Write-Verbose "Invoking INSERT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

function Get-WRADExcludedGroup {
    Param
	(
        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID
	)
	begin
	{
        $Table = 'WRADExcludeGroup'
        $Query = 'SELECT * FROM '+$Table
        
        if($ObjectGUID){
            $Query += ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"';
        }   
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
            Write-Error -Message $_.Exception.Message
			break
		}
	}
}

function New-WRADExcludedGroup {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID
	)
	begin
	{
        $Table = 'WRADExcludeGroup'
        $QueryEnd = ') '
        $QueryMiddle = ' ) VALUES ('
        $Query = 'INSERT INTO '+$Table+' ('
        $QueryValue = @()
        $QueryVariable = @()

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value
                $QueryVariable += '`'+$_+'`'
                $QueryValue += ' "'+$Value+'"'
            }
        }

        $Query += ($QueryVariable -join ", ")
        $Query += $QueryMiddle
        $Query += ($QueryValue -join ", ")
        $Query += $QueryEnd
	}
	Process
	{
		try
		{
            Write-Verbose "Checking for existent group";
            if((Get-WRADGroup -ObjectGUID $ObjectGUID) -eq $null){
                $CustomError = "Group with ObjectGUID "+$ObjectGUID+" does not exist"
                throw($CustomError) 
            }

            if ((Get-WRADExcludedGroup -ObjectGUID $ObjectGUID) -ne $null){
                $CustomError = "Duplicate entry for group with ObjectGUID "+$ObjectGUID
                throw($CustomError)
            }

            Write-Verbose "Invoking INSERT SQL Query on table $Table";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
			break
		}
	}
	End
	{
	}
}

Connect-WRADDatabase