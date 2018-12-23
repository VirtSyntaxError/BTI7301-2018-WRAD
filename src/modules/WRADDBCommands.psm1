Set-StrictMode -Version Latest

# Load MySQL Library
$null = [System.Reflection.Assembly]::LoadWithPartialName('MySql.Data')
# Define an array that reflects all the common parameters which will not be included in the SQL statements
$BuiltinParameters = @("ErrorAction","WarningAction","Verbose","ErrorVariable","WarningVariable","OutVariable","OutBuffer","Debug","Reference","NoObjectGUID","ExistentObjectGUID","UserPrincipalNameNoDomain","ShowCommonNames")

function Connect-WRADDatabase {
    begin
	{
        $PasswordPlain = Get-Content ($PSScriptRoot+"\db_pw.ini")
        $Username = "wradadmin"
        $Server = "localhost"
        $Port = "3306"
        $Database = "WRAD"
        $SSLMode = "none"

        $ConnectionString = "server=$Server;port=$Port;uid=$Username;pwd=$PasswordPlain;database=$Database;SSLMode=$SSLMode"
	}
	Process
	{
		try
		{
            if (-not (Get-Variable 'WRADDBConnection' -Scope Global -ErrorAction 'Ignore')) {
    
                [MySql.Data.MySqlClient.MySqlConnection]$Connection = New-Object MySql.Data.MySqlClient.MySqlConnection($ConnectionString)

                $Global:WRADDBConnection = $Connection

                Write-Verbose "Connecting to Database";
                $Connection.Open()
            } else {
                Write-Verbose "Connection already exists";
            }
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

    Connects to localhost and selects the database WRAD.

    .INPUTS

    None. You cannot pipe objects to Connect-WRADDatabase.

    .OUTPUTS

    Sets the current connection in a global variable named WRADDBConnection.

    .EXAMPLE

    C:\PS> Connect-WRADDatabase
    
    #>
}

function Close-WRADDBConnection {
    begin
	{
	}
	Process
	{
		try
		{
            $Global:WRADDBConnection.Dispose()
        }
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}

    <#
    .SYNOPSIS

    Close a WRAD Database connection.

    .DESCRIPTION

    Closes the database connection to localhost.

    .INPUTS

    None. You cannot pipe objects to Close-WRADDBConnection.

    .OUTPUTS

    Nothing.

    .EXAMPLE

    C:\PS> Close-WRADDBConnection
    
    #>
}

function Invoke-MariaDBQuery {
	Param
	(
        [Parameter()]
		[ValidateNotNullOrEmpty()]
        [MySql.Data.MySqlClient.MySqlConnection]
		$Connection,

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
            # Connect to database
            Write-Verbose "Connecting to database"
            Connect-WRADDatabase

            if(-not $Connection){
                $Connection = $Global:WRADDBConnection	
            }

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
        Finally {
            Write-Verbose "Closing database connection"
            Close-WRADDBConnection	
        }
	}
    <#
    .SYNOPSIS

    Invokes a MariaDB SQL query.

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

    C:\PS> Invoke-MariaDBQuery -Query "SELECT * FROM WRADUser"
    System.Row

    .EXAMPLE

    C:\PS> Invoke-MariaDBQuery -Query "SELECT * FROM WRADUser" -Connection $Connection
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
        # Prepare query with table and select statement
        $Table = 'WRADUser'
        if($Reference){
            $Table = 'WRADRefUser'
        }
        $Query = 'SELECT * FROM '+$Table;

        $FirstParameter = $true;

        # Loop through each parameter and add it to the select statement
        $PSBoundParameters.Keys | ForEach {
            #Exclude all common parameters
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

        # Get all users without a windows guid
        if($NoObjectGUID){
            if($FirstParameter){
                $Query += ' WHERE '
                $FirstParameter = $false
            } else {
                $Query += ' AND '
            }
            $Query += '`ObjectGUID` LIKE "noguid%"'
        }    

        # Get all users with the given UPN and ignore the domain
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

    Gets all or a selected WRAD users.

    .DESCRIPTION

    Gets all users which actually exist in the database. These are the fetched users from the Active Directory.
    The Output does not contain any deleted users.
    It is possible to load reference users with the -Reference switch.

    .PARAMETER Reference
    Specifies if all reference users should be shown instead of the actual one.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of an user. Only usable with actual users.

    .PARAMETER UserPrincipalName
    Specifies the exact UserPrincipalName of an user including the domain. Only usable with actual users.

    .PARAMETER UserPrincipalNameNoDomain
    Specifies the UserPrincipalName of an user without the domain. Only usable with actual users.

    .PARAMETER UserName
    Specifies the Username of an user. Only usable with reference users.
    
    .PARAMETER DisplayName
    Specifies the DisplayName of an user.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of an user.

    .PARAMETER NoObjectGUID
    Gets all users without an valid Windows GUID. This is only usable for reference users.

    .PARAMETER Disabled
    Specifies if an user is disabled.

    .PARAMETER Expired
    Specifies if an user is expired. Only usable with actual users.

    .INPUTS

    None. You cannot pipe objects to Get-WRADUser.

    .OUTPUTS

    System.Row. Get-WRADUser returns all parameters from the user table (actual or reference) in an row.

    .EXAMPLE

    C:\PS> Get-WRADUser -Reference -UserName furid

    ObjectGUID         : noguid1541155481408
    Username           : furid
    DisplayName        : Dario Furigo
    CreatedDate        : 15.10.2018 10:51:00
    Enabled            : True

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
            # Replace all double quotes for later
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

        # Loop through each parameter and add it to the insert statement
        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value

                # Change expired and enabled from boolean to int
                if($_ -eq "Expired" -or $_ -eq "Enabled"){
                    if($Value -eq $true ){
                        [Int]$Value = 1
                    } else {
                        [Int]$Value = 0
                    }
                } elseif ($_ -ne "LastLogonTimestamp"){
                    $Value = $Value.Replace('&DQ&','\"')
                }

                # If date is empty -> Insert NULL into table
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
            # Check if reference user exists
            Write-Verbose "Checking for already existent user";
            if ($Reference) {
                if($ObjectGUID){
                    if((Get-WRADUser -Reference -ObjectGUID $ObjectGUID) -ne $null){
                        $CustomError = "Duplicate entry for ObjectGUID "+$ObjectGUID
                        throw($CustomError) 
                    }
                }
            } else {
                # Check if actual user exists
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

    Creates a new WWRAD user.

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
    Specifies the LastLogonTimestamp of the user. This should be a DateTime value or $null.
    
    .PARAMETER DisplayName
    Specifies the DisplayName of the user.

    .PARAMETER Username
    Specifies the Username of the reference user.

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

    C:\PS> New-WRADUser -ObjectGUID d9dl998-03jlasd9-lasd99 -SAMAccountName testuser -DistinguishedName 'CN="testuser",CN="example",CN="local"' -UserPrincipalName test.user@test.local -DisplayName "testuser" -Description "Testuser for WRAD" -LastLogonTimestamp $timestamp -Enabled $false

    .EXAMPLE

    C:\PS> New-WRADUser -Reference -Username testuser -DisplayName "testuser" -Enabled $true

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
        # Prepare the SQL query
        $Table = ''
        $QueryEnd = ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
        if($Reference){
            $Table = 'WRADRefUser'
        } else {
            $Table = 'WRADUser'
            # Replace all double quotes for later
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

        # Loop through each parameter and add it to the update statement
        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_ -and $_ -ne "ObjectGUID") {
                [String]$Value = (Get-Variable -Name $_).Value

                # Change expired and enabled from boolean to int
                if($_ -eq "Expired" -or $_ -eq "Enabled"){
                    if($Value -eq $true ){
                        [Int]$Value = 1
                    } else {
                        [Int]$Value = 0
                    }
                } elseif ($_ -ne "LastLogonTimestamp"){
                    $Value = $Value.Replace('&DQ&','\"')
                }

                # If new ObjectGUID will be set
                if($_ -eq "NewObjectGUID"){
                    $QueryValue += ' `ObjectGUID` = "'+$NewObjectGUID+'" '
                } else {
                    # If date is empty -> Insert NULL into table
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

            # Check if parameter is set
            Write-Verbose "Checking if at least one parameter is set";
            if($QueryValue.Count -eq 0){
                $CustomError = "No parameter is set for user with ObjectGUID "+$ObjectGUID
                throw($CustomError) 
            }

            # Check if user to change exists
            Write-Verbose "Checking for existent user";
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

    Updates a WRAD user.

    .DESCRIPTION

    Updates a user in the database with the given parameters.
    
    .PARAMETER Reference
    Specifies if a reference user should be updated instead of an actual one.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of the user.

    .PARAMETER UserPrincipalName
    Specifies the UserPrincipalName of the user.

    .PARAMETER DistinguishedName
    Specifies the DistinguishedName of the user. Like CN="testuser",CN="example",CN="local"

    .PARAMETER LastLogonTimestamp
    Specifies the LastLogonTimestamp of the user. This should be a DateTime value or $null.
    
    .PARAMETER DisplayName
    Specifies the DisplayName of the user.

    .PARAMETER Username
    Specifies the Username of the reference user.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the user.

    .PARAMETER NewObjectGUID
    Specifies a new Globally Unique Identifier for a reference user. This is used to change from noguid to a valid Windows GUID.

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

    .EXAMPLE

    C:\PS> Update-WRADUser -Reference -ObjectGUID noguid99999 -NewObjectGUID op3n-93kae-903ld9-22kdl -Enabled $false
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
        # Prepare the quqery for the delete
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
            # Check if user to delete exists
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

<#
    .SYNOPSIS

    Deletes a WRAD user.

    .DESCRIPTION

    Deletes the specified WRAD user in the database.

    .PARAMETER Reference
    Specifies if a reference user should be deleted instead of an actual one.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the user.

    .INPUTS

    None. You cannot pipe objects to Remove-WRADUser.

    .OUTPUTS

    Nothing. Remove-WRADUser returns an error if something is wrong.

    .EXAMPLE

    C:\PS> Remove-WRADUser -ObjectGUID d9dl998-03jlasd9-lasd99

    .EXAMPLE

    C:\PS> Remove-WRADUser -Reference -ObjectGUID noguid1541155481408

    #>
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
        # Prepare SQL query for select statement
        $Table = 'WRADGroup'
        $QueryEnd = ''
        if($Reference){
            $Table = 'WRADRefGroup'
        }
        $Query = 'SELECT * FROM '+$Table;

        $FirstParameter = $true;

        # Loop through each parameter and add it to the SELECT statement
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
        
        # Get all WRAD groups with a synthetic guid like noguid*
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

<#
    .SYNOPSIS

    Gets all WRAD groups.

    .DESCRIPTION

    Gets all WRAD groups from the database with the specified parameters.

    .PARAMETER Reference
    Specifies if a reference group should be created instead of an actual one.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of the group.
    
    .PARAMETER CommonName
    Specifies the CommonName of the group.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the group.

    .PARAMETER GroupType
    Specifies the group type of the group. This can be either 'DomainLocal','Global' or 'Universal'.

    .PARAMETER GroupTypeSecurity
    Specifies the security type of the group. This can be either 'Security' or 'Distribution'.

    .PARAMETER NoObjectGUID
    Gets all groups without an valid Windows GUID. This is only usable for reference groups.

    .INPUTS

    None. You cannot pipe objects to Get-WRADGroup.

    .OUTPUTS

    System.Row. Get-WRADGroup returns all parameters from the group table (actual or reference) in an row.

    .EXAMPLE

    C:\PS> Get-WRADGroup -GroupTypeSecurity Distribution -CommonName MaurerMail

    ObjectGUID        : 936DA01F-9ABD-4D9D-80C7-02AF85C822A8
    CreatedDate       : 18.11.2018 12:47:03
    LastModifiedDate  : 18.11.2018 12:47:03
    SAMAccountName    : MaurerMail
    GroupType         : DomainLocal
    GroupTypeSecurity : Distribution
    CommonName        : MaurerMail
    DistinguishedName : CN="MaurerMail", CN="test", CN="local"
    Description       :

    .EXAMPLE

    C:\PS> Get-WRADGroup -Reference

    ObjectGUID        : noguid0393822221452
    CreatedDate       : 02.11.2018 11:52:11
    GroupType         : Global
    GroupTypeSecurity : Security
    CommonName        : Architektur

    ObjectGUID        : noguid1541155564978
    CreatedDate       : 02.11.2018 10:46:04
    GroupType         : DomainLocal
    GroupTypeSecurity : Distribution
    CommonName        : DesignMail

    #>
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
        # Prepare the SQL statement
        $Table = ''
        $QueryEnd = ') '
        $QueryMiddle = ' ) VALUES ('
        if($Reference){
            $Table = 'WRADRefGroup'
        } else {
            $Table = 'WRADGroup'
            # Replace all double quotes for later
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

        # Loop through each parameter and add it to the insert statement
        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value
                $QueryVariable += '`'+$_+'`'

                # Replace the placeholder with actual escaped double quotes
                $QueryValue += ' "'+$Value.Replace('&DQ&','\"')+'"'
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
            # Check if group exists, if yes throw an error
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

    Creates a new WRAD group.

    .DESCRIPTION

    Creates a new WRAD group in the database with the given parameters.

    
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
    Specifies the GroupTypeSecurity of the group. This should be either 'Security' or 'Distribution'.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the group.

    .PARAMETER Description
    Specifies the description.

    .INPUTS

    None. You cannot pipe objects to New-WRADGroup.

    .OUTPUTS

    Nothing. New-WRADGroup returns an error if something is wrong.

    .EXAMPLE

    C:\PS> New-WRADGroup -ObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8 -SAMAccountName "Domain Powerusers" -CommonName "Domain Powerusers" -DistinguishedName 'CN="Domain Powerusers",CN="example",CN="local"' -GroupTypeSecurity Security -GroupType DomainLocal

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
        # Prepare the SQL UPDATE statement
        $Table = ''
        $QueryEnd = ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
        if($Reference){
            $Table = 'WRADRefGroup'
        } else {
            # Replace all double quotes for later
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

        # Loop through each parameter and add it to the UPDATE statement
        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_ -and $_ -ne "ObjectGUID") {      
                # If NewObjectGUID is set the ObjectGUID should be changed as well
                if($_ -eq "NewObjectGUID"){
                    $QueryValue += ' `ObjectGUID` = "'+$NewObjectGUID+'" '
                } else {
                    [String]$Value = (Get-Variable -Name $_).Value
                    # Replace the placeholder back to double quotes
                    $QueryValue += ' `'+$_+'` = "'+$Value.Replace('&DQ&','\"')+'" '
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
            # Check if a parameter is set
            Write-Verbose "Checking if at least one parameter is set";
            if($QueryValue.Count -eq 0){
                $CustomError = "No parameter is set for group with ObjectGUID "+$ObjectGUID
                throw($CustomError) 
            }

            # Check if group to update exists or throw an error
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

    Updates a WRAD group.

    .DESCRIPTION

    Updates a WRAD group in the database with the given parameters.

    .PARAMETER Reference
    Specifies if a reference group should be updated instead of an actual one.

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
    
    .PARAMETER NewObjectGUID
    Specifies a new Globally Unique Identifier for a reference group. This is used to change from noguid to a valid Windows GUID.

    .PARAMETER Description
    Specifies the description.

    .INPUTS

    None. You cannot pipe objects to Update-WRADGroup.

    .OUTPUTS

    Nothing. Update-WRADGroup returns an error if something is wrong.

    .EXAMPLE

    C:\PS> Update-WRADGroup -ObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8 -CommonName "New Groupname"

    .EXAMPLE

    C:\PS> Update-WRADGroup -Reference -ObjectGUID noguid374927339119 -NewObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

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
        # Prepare the DELETE statement
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
            # Check if group to delete exists
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
<#
    .SYNOPSIS

    Deletes a WRAD group.

    .DESCRIPTION

    Deletes the specified WRAD group in the database.

    .PARAMETER Reference
    Specifies if a reference group should be deleted instead of an actual one.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the group.

    .INPUTS

    None. You cannot pipe objects to Remove-WRADGroup.

    .OUTPUTS

    Nothing. Remove-WRADGroup returns an error if something is wrong.

    .EXAMPLE

    C:\PS> Remove-WRADGroup -ObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    .EXAMPLE

    C:\PS> Remove-WRADGroup -Reference -ObjectGUID noguid1541155481408

    #>
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

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$ShowCommonNames,

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
            # If the parameter ShowCommonNames is set the SQL query joins the WRADRefUser and WRADRefGroup tables to display the common names
            if($ShowCommonNames){
                $QueryEnd = ' INNER JOIN WRADRefUser ON WRADRefUserGroup.UserObjectGUID = WRADRefUser.ObjectGUID INNER JOIN WRADRefGroup ON WRADRefUserGroup.GroupObjectGUID = WRADRefGroup.ObjectGUID'
                $Query = 'SELECT WRADRefUser.Username,WRADRefGroup.CommonName,WRADRefUserGroup.CreatedDate FROM '+$Table;
            } else {
                $Query = 'SELECT * FROM '+$Table;
            }

            # If the ExistentObjectGUID parameter is set the SQL query exclude als non-Windows GUIDs
            if($ExistentObjectGUID){
                $QueryEnd += ' WHERE WRADRefUserGroup.UserObjectGUID NOT LIKE "noguid%" AND WRADRefUserGroup.GroupObjectGUID NOT LIKE "noguid%"'
                $FirstParameter = $false
            }
        }

        # Loop through each parameter and add it to the SELECT statement
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
<#
    .SYNOPSIS

    Gets all WRAD user to group memberships.

    .DESCRIPTION

    Gets all WRAD user to group memberships from the database with the specified parameters.

    .PARAMETER Reference
    Specifies if all reference user to group membership should be selected instead of an actual one.

    .PARAMETER ExistentObjectGUID
    Show only the membership which have valid Windows GUIDs.
    
    .PARAMETER ShowCommonName
    Show the real names of the users and groups instead of the GUIDs.

    .PARAMETER UserObjectGUID
    Specifies the Globally Unique Identifier of the user.

    .PARAMETER GroupObjectGUID
    Specifies the Globally Unique Identifier of the group.

    .INPUTS

    None. You cannot pipe objects to Get-WRADGroupOfUser.

    .OUTPUTS

    System.Row. Get-WRADGroupOfUser returns all parameters from the UserGroup table (actual or reference) in an row.

    .EXAMPLE

    C:\PS> Get-WRADGroupOfUser -Reference

    CreatedDate         UserObjectGUID          GroupObjectGUID
    -----------         --------------          ---------------
    02.11.2018 10:46:29 noguid1541155481408     noguid1541155564978
    02.11.2018 10:53:34 noguid1541155481408     936DA01F-9ABD-4D9D-80C7-02AF85C822A8
    02.11.2018 10:53:43 op3n-93kae-903ld9-22kdl 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    .EXAMPLE

    C:\PS> Get-WRADGroupOfUser -Reference -ShowCommonNames

    Username    CommonName     CreatedDate
    --------    ----------     -----------
    BrunoM      Architektur    02.11.2018 10:46:29
    BrunoM      MaurerMail     02.11.2018 10:53:34
    RudolfK     MaurerMail     02.11.2018 10:53:43

    #>
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
        # Prepare SQL query
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

        # Loop through each parameter and add it to the INSERT statement
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
            # Check for existing user to group mapping and throw error if it exists or if either user or group not exists
            # This will be performaned for actual or reference memberships
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

<#
    .SYNOPSIS

    Insert a new WRAD user to group membership.

    .DESCRIPTION

    Insert a new WRAD user to group membership into the database.

    .PARAMETER Reference
    Specifies if the insert is for a reference user to group membership instead of an actual one.

    .PARAMETER UserObjectGUID
    Specifies the Globally Unique Identifier of the user.

    .PARAMETER GroupObjectGUID
    Specifies the Globally Unique Identifier of the group.

    .INPUTS

    None. You cannot pipe objects to New-WRADGroupOfUser.

    .OUTPUTS

    Nothing. New-WRADGroupOfUser returns an error if something is wrong.

    .EXAMPLE

    C:\PS> New-WRADGroupOfUser -Reference -UserObjectGUID noguid1541155481408 -GroupObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    .EXAMPLE

    C:\PS> New-WRADGroupOfUser -UserObjectGUID 738ldas-3928lasdf-29asdfkl -GroupObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    #>
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
        # Prepare query
        $Table = ''
        if($Reference){
            $Table = 'WRADRefUserGroup'
        } else {
            $Table = 'WRADUserGroup'
        }
        $Query = 'DELETE FROM '+$Table+' WHERE '
        $QueryValue = @()

        # Loop through each parameter and add it to the DELETE statement
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
            # Check if user to group mapping exists
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
<#
    .SYNOPSIS

    Delete an existing WRAD user to group membership.

    .DESCRIPTION

    Delete an existing WRAD user to group membership from the database.

    .PARAMETER Reference
    Specifies if the delete is for a reference user to group membership instead of an actual one.

    .PARAMETER UserObjectGUID
    Specifies the Globally Unique Identifier of the user.

    .PARAMETER GroupObjectGUID
    Specifies the Globally Unique Identifier of the group.

    .INPUTS

    None. You cannot pipe objects to Remove-WRADGroupOfUser.

    .OUTPUTS

    Nothing. Remove-WRADGroupOfUser returns an error if something is wrong.

    .EXAMPLE

    C:\PS> Remove-WRADGroupOfUser -Reference -UserObjectGUID noguid1541155481408 -GroupObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    .EXAMPLE

    C:\PS> Remove-WRADGroupOfUser -UserObjectGUID 738ldas-3928lasdf-29asdfkl -GroupObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    #>
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

        [Parameter(ParameterSetName="REFERENCE", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$ShowCommonNames,

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
        # Prepare the SQL statements
        $Table = 'WRADGroupGroup'
        $QueryEnd = ''
        $Query = 'SELECT * FROM '+$Table;
        if($Reference){
            $Table = 'WRADRefGroupGroup'
            # If ShowCommonNames is set the query joins the group tables to get the names instead of the GUID
            if($ShowCommonNames){
                $QueryEnd = ' INNER JOIN WRADRefGroup AS cg ON WRADRefGroupGroup.ChildGroupObjectGUID = cg.ObjectGUID INNER JOIN WRADRefGroup AS pg ON WRADRefGroupGroup.ParentGroupObjectGUID = pg.ObjectGUID'
                $Query = 'SELECT cg.CommonName AS ChildGroup,pg.CommonName AS ParentGroup,WRADRefGroupGroup.CreatedDate FROM '+$Table;
            } else {
                $Query = 'SELECT * FROM '+$Table;
            }
  
            # Get only valid Windows GUIDs
            if($ExistentObjectGUID){
                $QueryEnd += ' WHERE WRADRefGroupGroup.ChildGroupObjectGUID NOT LIKE "noguid%" AND WRADRefGroupGroup.ParentGroupObjectGUID NOT LIKE "noguid%"'
                $FirstParameter = $false
            }
        }
        
        $FirstParameter = $true;

        # Loop through each parameter and add it to the SELECT statement
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

<#
    .SYNOPSIS

    Gets all WRAD group to group memberships.

    .DESCRIPTION

    Gets all WRAD group to group memberships from the database with the specified parameters.

    .PARAMETER Reference
    Specifies if all reference group to group membership should be selected instead of an actual one.

    .PARAMETER ExistentObjectGUID
    Show only the membership which have valid Windows GUIDs.
    
    .PARAMETER ShowCommonName
    Show the real names of the groups instead of the GUIDs.

    .PARAMETER ChildGroupObjectGUID
    Specifies the Globally Unique Identifier of the child group.

    .PARAMETER ParentGroupObjectGUID
    Specifies the Globally Unique Identifier of the parent group.

    .INPUTS

    None. You cannot pipe objects to Get-WRADGroupOfGroup.

    .OUTPUTS

    System.Row. Get-WRADGroupOfGroup returns all parameters from the GroupGroup table (actual or reference) in an row.

    .EXAMPLE

    C:\PS> Get-WRADGroupOfGroup -Reference

    CreatedDate         UserObjectGUID          GroupObjectGUID
    -----------         --------------          ---------------
    02.11.2018 10:46:29 noguid1541155481408     noguid1541155564978

    .EXAMPLE

    C:\PS> Get-WRADGroupOfGroup -Reference -ShowCommonNames

    ChildGroup ParentGroup CreatedDate
    ---------- ----------- -----------
    child01    parent01    02.11.2018 11:52:38

    #>
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
        # Prepare the INSERT query
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

        # Loop through each parameter and add it to the INSERT statement
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
            # Check if group to group mapping exists and both groups are in the database. If not throw an error.
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
<#
    .SYNOPSIS

    Insert a new WRAD group to group membership.

    .DESCRIPTION

    Insert a new WRAD group to group membership into the database.

    .PARAMETER Reference
    Specifies if the insert is for a reference group to group membership instead of an actual one.

    .PARAMETER ChildGroupObjectGUID
    Specifies the Globally Unique Identifier of the child group.

    .PARAMETER ParentGroupObjectGUID
    Specifies the Globally Unique Identifier of the parent group.

    .INPUTS

    None. You cannot pipe objects to New-WRADGroupOfGroup.

    .OUTPUTS

    Nothing. New-WRADGroupOfGroup returns an error if something is wrong.

    .EXAMPLE

    C:\PS> New-WRADGroupOfGroup -Reference -ChildGroupObjectGUID noguid1541155481408 -ParentGroupObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    .EXAMPLE

    C:\PS> New-WRADGroupOfGroup -ChildGroupObjectGUID 738ldas-3928lasdf-29ad43kl -ParentGroupObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    #>
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
        # Prepare query for DELETE statement
        $Table = ''
        if($Reference){
            $Table = 'WRADRefGroupGroup'
        } else {
            $Table = 'WRADGroupGroup'
        }
        $Query = 'DELETE FROM '+$Table+' WHERE '
        $QueryValue = @()

        # Loop through each parameter and add it to the DELETE statement
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
            # Check if mapping from child group to parent group exists
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
<#
    .SYNOPSIS

    Delete an existing WRAD group to group membership.

    .DESCRIPTION

    Delete an existing WRAD group to group membership from the database.

    .PARAMETER Reference
    Specifies if the delete is for a reference group to group membership instead of an actual one.

    .PARAMETER ChildGroupObjectGUID
    Specifies the Globally Unique Identifier of the child group.

    .PARAMETER ParentGroupObjectGUID
    Specifies the Globally Unique Identifier of the parent group.

    .INPUTS

    None. You cannot pipe objects to Remove-WRADGroupOfGroup.

    .OUTPUTS

    Nothing. Remove-WRADGroupOfGroup returns an error if something is wrong.

    .EXAMPLE

    C:\PS> Remove-WRADGroupOfGroup -Reference -ChildGroupObjectGUID noguid1541155481408 -ParentGroupObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    .EXAMPLE

    C:\PS> Remove-WRADGroupOfGroup -ChildGroupObjectGUID 738ldas-3928lasdf-29asdfkl -ParentGroupObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    #>
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
<#
    .SYNOPSIS

    Gets the history of a WRAD user.

    .DESCRIPTION

    Gets the history of a WRAD user from the database. This includes any updates or deletes on this user.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the user.

    .INPUTS

    None. You cannot pipe objects to Get-WRADHistoryOfUser.

    .OUTPUTS

    System.Row. Get-WRADHistoryOfUser returns all parameters from the UserArchive table in an row.

    .EXAMPLE

    C:\PS> Get-WRADHistoryOfUser -ObjectGUID op3n-93kae-903ld9-22kdl

    ArchiveID         : 1
    userPrincipalName : RudolfK@example.local
    SAMAccountName    : RudolfK
    DistinguishedName : CN="RudolfK",CN="Users",CN="example",CN="local"
    ObjectGUID        : op3n-93kae-903ld9-22kdl
    OperationType     : u
    VersionStartTime  : 02.11.2018 10:20:29
    VersionEndTime    : 02.11.2018 10:24:48
    DisplayName       : RudolfK
    Description       : 
    Enabled           : False
    Expired           : False

    ArchiveID         : 2
    userPrincipalName : RudolfK@example.local
    SAMAccountName    : RudolfK
    DistinguishedName : CN="RudolfK",CN="Users",CN="example",CN="local"
    ObjectGUID        : op3n-93kae-903ld9-22kdl
    OperationType     : u
    VersionStartTime  : 02.11.2018 10:24:48
    VersionEndTime    : 02.11.2018 10:25:23
    DisplayName       : RudolfK
    Description       : 
    Enabled           : True
    Expired           : False

    ArchiveID         : 3
    userPrincipalName : RudolfK@example.local
    SAMAccountName    : RudolfK
    DistinguishedName : CN="RudolfK",CN="Users",CN="example",CN="local"
    ObjectGUID        : op3n-93kae-903ld9-22kdl
    OperationType     : d
    VersionStartTime  : 02.11.2018 10:25:23
    VersionEndTime    : 02.11.2018 10:27:17
    DisplayName       : RudolfK
    Description       : 
    Enabled           : True
    Expired           : False

    #>
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
<#
    .SYNOPSIS

    Gets the history of a WRAD group.

    .DESCRIPTION

    Gets the history of a WRAD group from the database. This includes any updates or deletes on this group.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of the group.

    .INPUTS

    None. You cannot pipe objects to Get-WRADHistoryOfGroup.

    .OUTPUTS

    System.Row. Get-WRADHistoryOfGroup returns all parameters from the GroupArchive table in an row.

    .EXAMPLE

    C:\PS> Get-WRADHistoryOfGroup -ObjectGUID 936DA01F-9ABD-4D9D-80C7-02AF85C822A8

    ArchiveID         : 1
    ObjectGUID        : 936DA01F-9ABD-4D9D-80C7-02AF85C822A8
    CommonName        : MaurerMail
    SAMAccountName    : MaurerMail
    GroupType         : DomainLocal
    GroupTypeSecurity : Distribution
    VersionStartTime  : 18.11.2018 12:44:05
    OperationType     : u
    VersionEndTime    : 18.11.2018 12:46:50
    DistinguishedName : CN="MaurerMail", CN="example", CN="local"
    Description       : 

    ArchiveID         : 2
    ObjectGUID        : 936DA01F-9ABD-4D9D-80C7-02AF85C822A8
    CommonName        : MaurerMail
    SAMAccountName    : MaurerMail
    GroupType         : DomainLocal
    GroupTypeSecurity : Distribution
    VersionStartTime  : 18.11.2018 12:46:50
    OperationType     : d
    VersionEndTime    : 18.11.2018 12:47:00
    DistinguishedName : CN="MaurerMail", CN="Groups", CN="example", CN="local"
    Description       : 

    #>
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
<#
    .SYNOPSIS

    Gets all deleted WRAD users.

    .DESCRIPTION

    Gets all deleted WRAD users from the database. These are users which have exist in Active Directory but have been deleted later on.

    .INPUTS

    None. You cannot pipe objects to Get-WRADDeletedUser.

    .OUTPUTS

    System.Row. Get-WRADDeletedUser returns all parameters from all deleted user in the UserArchive table in an row.

    .EXAMPLE

    C:\PS> Get-WRADDeletedUser

    ArchiveID         : 3
    userPrincipalName : RudolfK@example.local
    SAMAccountName    : RudolfK
    DistinguishedName : CN="RudolfK",CN="Users",CN="example",CN="local"
    ObjectGUID        : op3n-93kae-903ld9-22kdl
    OperationType     : d
    VersionStartTime  : 02.11.2018 10:25:23
    VersionEndTime    : 02.11.2018 10:27:17
    DisplayName       : RudolfK
    Description       : 
    Enabled           : True
    Expired           : False

    #>
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
<#
    .SYNOPSIS

    Gets all deleted WRAD groups.

    .DESCRIPTION

    Gets all deleted WRAD groups from the database. These are groups which have exist in Active Directory but have been deleted later on.

    .INPUTS

    None. You cannot pipe objects to Get-WRADDeletedGroup.

    .OUTPUTS

    System.Row. Get-WRADDeletedGroup returns all parameters from all deleted group in the GroupArchive table in an row.

    .EXAMPLE

    C:\PS> Get-WRADDeletedGroup

    ArchiveID         : 2
    ObjectGUID        : 936DA01F-9ABD-4D9D-80C7-02AF85C822A8
    CommonName        : MaurerMail
    SAMAccountName    : MaurerMail
    GroupType         : DomainLocal
    GroupTypeSecurity : Distribution
    VersionStartTime  : 18.11.2018 12:46:50
    OperationType     : d
    VersionEndTime    : 18.11.2018 12:47:00
    DistinguishedName : CN="MaurerMail", CN="Groups", CN="example", CN="local"
    Description       : 

    #>
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
<#
    .SYNOPSIS

    Gets WRAD application settings.

    .DESCRIPTION

    Gets WRAD application settings which are stored in the database.

    .PARAMETER SettingName
    Filters only the settings which match SettingName

    .INPUTS

    None. You cannot pipe objects to Get-WRADSetting.

    .OUTPUTS

    System.Row. Get-WRADSetting returns all settings in an row.

    .EXAMPLE

    C:\PS> Get-WRADSetting

    SettingID SettingName             SettingValue
    --------- -----------             ------------
            1 ADRoleDepartmentLead                
            2 ADRoleAuditor                       
            3 ADRoleSysAdmin                      
            4 ADRoleApplOwner                     
            5 LogExternal             none        
            6 LogFilePath                         
            7 LogSyslogServer                     
            8 LogSyslogServerProtocol udp         
            9 SearchBase                         

    .EXAMPLE
    C:\PS> Get-WRADSetting -SettingName LogExternal

    SettingID SettingName SettingValue
    --------- ----------- ------------
            5 LogExternal none
    #>
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
        # Replace all double quotes and backslashes to represent them in the database
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

        # Loop through each parameter and add it to the UPDATE statement
        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                $Value = (Get-Variable -Name $_).Value

                # Insert the escaped double quotes and backslashes 
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
<#
    .SYNOPSIS

    Updates WRAD application settings.

    .DESCRIPTION

    Updates WRAD application settings which are stored in the database.

    .PARAMETER ADRoleDepartmentLead
    Changes the setting ADRoleDepartmentLead

    .PARAMETER ADRoleAuditor
    Changes the setting ADRoleAuditor

    .PARAMETER ADRoleSysAdmin
    Changes the setting ADRoleSysAdmin

    .PARAMETER ADRoleApplOwner
    Changes the setting ADRoleApplOwner

    .PARAMETER LogExternal
    Changes the setting LogExternal. Allowed options are none, file or syslog.

    .PARAMETER LogFilePath
    Changes the setting LogFilePath

    .PARAMETER LogSyslogServer
    Changes the setting LogSyslogServer
    
    .PARAMETER LogSyslogServerProtocol
    Changes the setting LogSyslogServerProtocol. Allowed options are tcp and udp
    
    .PARAMETER SearchBase
    Changes the setting SearchBase

    .INPUTS

    None. You cannot pipe objects to Update-WRADSetting.

    .OUTPUTS

    Nothing.

    .EXAMPLE

    C:\PS> Update-WRADSetting -LogExternal file -LogFilePath "C:\WRADLogs"

    #>
}

function Get-WRADLog {
[CmdletBinding(DefaultParameterSetName="LAST")]
    Param
	(
        [Parameter(ParameterSetName="LAST", Mandatory=$false)]
        [Parameter(ParameterSetName="FIRST", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Int]$LogSeverity = -1,

        [Parameter(ParameterSetName="LAST", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Int]$Last,

        [Parameter(ParameterSetName="FIRST", Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Int]$First
	)
	begin
	{
        $Query = 'SELECT * FROM WRADLog';	

        if($LogSeverity -ge 0) {
            $Query += ' WHERE `LogSeverity` = '+$LogSeverity
        }

        if($Last -gt 0) {
            $Query += ' ORDER BY `LogTimestamp` DESC LIMIT '+$Last
        }

        if($First -gt 0) {
            $Query += ' ORDER BY `LogTimestamp` ASC LIMIT '+$First
        }

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
<#
    .SYNOPSIS

    Gets WRAD logs.

    .DESCRIPTION

    Gets WRAD logs which are stored in the database.

    .PARAMETER LogSeverity
    Filters only the which match LogSeverity

    .PARAMETER Last
    Gets the newest amount of entries
    
    .PARAMETER Last
    Gets the oldest amount of entries

    .INPUTS

    None. You cannot pipe objects to Get-WRADLog.

    .OUTPUTS

    System.Row. Get-WRADLog returns all logs in an row.

    .EXAMPLE

    C:\PS> Get-WRADLog

    LogID LogTimestamp        LogSeverity LogText
    ----- ------------        ----------- -------
        3 14.12.2018 11:58:32           2 Added new user sebastian.vettel
        4 14.12.2018 15:58:45           2 Added new group formula1
        5 15.12.2018 15:58:50           2 Added sebastian.vettel to group formula1
        6 15.12.2018 15:58:51           2 Added new group ferrari
        7 18.12.2018 15:58:51           0 Deleted user sebastian.vettel
        8 19.12.2018 15:58:53           0 Deleted group ferrari                        

    #>
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
<#
    .SYNOPSIS

    Insert a new WRAD log entry.

    .DESCRIPTION

    Insert a new WRAD log entry into the Database.

    .PARAMETER LogSeverity
    Specify the log severity

    .PARAMETER LogText
    Specify log text

    .INPUTS

    None. You cannot pipe objects to New-WRADLog.

    .OUTPUTS

    Nothing.

    .EXAMPLE

    C:\PS> New-WRADLog -LogSeverity 2 -LogText "Added new group honda"                     

    #>
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
<#
    .SYNOPSIS

    Gets WRAD excluded users.

    .DESCRIPTION

    Gets all WRAD excluded users from the Database.

    .INPUTS

    None. You cannot pipe objects to Get-WRADExcludedUser.

    .OUTPUTS

    System.Row. Get-WRADExcludedUser returns all excluded users in an row.

    .EXAMPLE

    C:\PS> Get-WRADExcludedUser 
      
    ExcludeID ObjectGUID        
    --------- ------------        
            3 0b9462b3-3bc3-4849-a509-b5d5eb061461
            4 734d3f7c-961e-467f-b4fb-72fce8d4cb6d
            5 dc33b32c-af4f-4f07-8efd-e9a37f67f1da

    #>
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
<#
    .SYNOPSIS

    Adds new WRAD excluded users.

    .DESCRIPTION

    Adds a new WRAD excluded users into the Database.

    .PARAMETER ObjectGUID

    The ObjectGUID from the user which will be excluded for some operations.

    .INPUTS

    None. You cannot pipe objects to New-WRADExcludedUser.

    .OUTPUTS

    Nothing.

    .EXAMPLE

    C:\PS> New-WRADExcludedUser -ObjectGUID 734d3f7c-961e-467f-b4fb-72fce8d4cb6d

 #>
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
<#
    .SYNOPSIS

    Gets WRAD excluded groups.

    .DESCRIPTION

    Gets all WRAD excluded groups from the Database.

    .INPUTS

    None. You cannot pipe objects to Get-WRADExcludedGroup.

    .OUTPUTS

    System.Row. Get-WRADExcludedGroup returns all excluded users in an row.

    .EXAMPLE

    C:\PS> Get-WRADExcludedGroup 
      
    ExcludeID ObjectGUID        
    --------- ------------        
           55 97656ab1-edbf-4df2-a9bf-13c91e70dcdb
           78 586b0ff2-9f51-4319-9645-62cc61207a2c

    #>
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
<#
    .SYNOPSIS

    Adds new WRAD excluded group.

    .DESCRIPTION

    Adds a new WRAD excluded group into the Database. This group will be excluded for some operations.

    .PARAMETER ObjectGUID

    The ObjectGUID from the group.

    .INPUTS

    None. You cannot pipe objects to New-WRADExcludedGroup.

    .OUTPUTS

    Nothing.

    .EXAMPLE

    C:\PS> New-WRADExcludedGroup -ObjectGUID 54f3acba-39d1-4af8-863b-d32f682686dc

 #>
}

function Get-WRADEvent {
    Param
	(
        [Parameter(Mandatory=$false)]
		[AllowEmptyString()]
		[String]$SrcUserObjectGUID,

        [Parameter(Mandatory=$false)]
		[AllowEmptyString()]
		[String]$SrcGroupObjectGUID,

        [Parameter(Mandatory=$false)]
		[AllowEmptyString()]
		[String]$SrcRefUserObjectGUID,

        [Parameter(Mandatory=$false)]
		[AllowEmptyString()]
		[String]$SrcRefGroupObjectGUID,

        [Parameter(Mandatory=$false)]
		[AllowEmptyString()]
		[String]$DestGroupObjectGUID,

        [Parameter(Mandatory=$false)]
		[AllowEmptyString()]
		[String]$DestRefGroupObjectGUID,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Int]$EventType,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$NotResolved
	)
	begin
	{
        $Table = 'WRADEvent'
        $Query = 'SELECT * FROM '+$Table;
        $FirstParameter = $true	

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                $Value = (Get-Variable -Name $_ ).Value
                        
                if($FirstParameter){
                    $Query += ' WHERE '
                    $FirstParameter = $false
                } else {
                    $Query += ' AND '
                }

                if($_ -eq "NotResolved"){
                    $Query += ' `ResolvedDate` IS NULL'
                } else {
                    if($Value -eq ""){
                        $Query += '`'+$_+'` IS NULL'
                    } else {
                        $Query += '`'+$_+'` = "'+$Value+'"'
                    }
                }
            }
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
<#
    .SYNOPSIS

    Gets all WRAD events.

    .DESCRIPTION

    Gets all WRAD events from the Database. These events show the difference between the reference and the actual Active Directory.

    .PARAMETER SrcUserObjectGUID
    This parameter represents the actual source user.

    .PARAMETER SrcGroupObjectGUID
    This parameter represents the actual source group.

    .PARAMETER SrcRefUserObjectGUID
    This parameter represents the reference source user.

    .PARAMETER SrcRefGroupObjectGUID
    This parameter represents the reference source group.

    .PARAMETER DestGroupObjectGUID
    This parameter represents the actual destination group.

    .PARAMETER DestRefGroupObjectGUID
    This parameter represents the reference destination group.

    .PARAMETER EventType
    The type of the event (User not in Group, Group not in Group and so on...)

    .PARAMETER NotResolved
    The switch if the event is resolved or not.

    .INPUTS

    None. You cannot pipe objects to Get-WRADEvent.

    .OUTPUTS

    System.Row. Get-WRADEvent returns all events in an row.

    .EXAMPLE

    C:\PS> Get-WRADEvent 
      
    EventID                : 23
    CreatedDate            : 04.11.2018 10:50:23
    ResolvedDate           : 08.11.2018 13:59:26
    SrcUserObjectGUID      :
    SrcGroupObjectGUID     :
    SrcRefUserObjectGUID   : noguid1541155481408
    SrcRefGroupObjectGUID  :
    DestGroupObjectGUID    :
    DestRefGroupObjectGUID :
    EventType              : 1

    EventID                : 130
    CreatedDate            : 04.11.2018 10:50:51
    ResolvedDate           :
    SrcUserObjectGUID      :
    SrcGroupObjectGUID     :
    SrcRefUserObjectGUID   : noguid1541155481408
    SrcRefGroupObjectGUID  :
    DestGroupObjectGUID    :
    DestRefGroupObjectGUID :
    EventType              : 2

    #>
}

function Set-WRADEventResolved {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Int]$EventID
	)
	begin
	{
        $Table = 'WRADEvent'
        [String]$Date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
        $Query = 'UPDATE '+$Table+' SET `ResolvedDate` = "'+$Date+'" WHERE `EventID` = '+$EventID;	


	}
	Process
	{
		try
		{
			Write-Verbose "Invoking UPDATE SQL Query on table $Table";
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
    <#
    .SYNOPSIS

    Set an WRAD as resolved.

    .DESCRIPTION

    Set an WRAD as resolved in the Database. These events show the difference between the reference and the actual Active Directory.

    .PARAMETER EventID
    The ID of the event which is resolved.

    .INPUTS

    None. You cannot pipe objects to Set-WRADEventResolved.

    .OUTPUTS

    Nothing.

    .EXAMPLE

    C:\PS> Set-WRADEventResolved -EventID 130  
  
    #>
}

function New-WRADEvent {
    Param
	(
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
		[String]$SrcUserObjectGUID,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
		[String]$SrcGroupObjectGUID,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
		[String]$SrcRefUserObjectGUID,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
		[String]$SrcRefGroupObjectGUID,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
		[String]$DestGroupObjectGUID,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
		[String]$DestRefGroupObjectGUID,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Int]$EventType
	)
	begin
	{
        $Table = 'WRADEvent'
        $QueryEnd = ') '
        $QueryMiddle = ' ) VALUES ('    
        $Query = 'INSERT INTO '+$Table+' ('
        $QueryValue = @()
        $QueryVariable = @()
        $Validation = "Get-WRADEvent "

        $PSBoundParameters.Keys | ForEach {
            if ($BuiltinParameters -notcontains $_) {
                [String]$Value = (Get-Variable -Name $_).Value

                $QueryVariable += '`'+$_+'`'
                $Validation += '-'+$_+' '
                if($Value -eq ""){
                    $QueryValue += ' NULL'
                    $Validation += ' $null '
                } else {
                    $QueryValue += ' "'+$Value+'"'
                    $Validation += $Value+' '
                }
            }
        }

        $Query += ($QueryVariable -join ", ")
        $Query += $QueryMiddle
        $Query += ($QueryValue -join ", ")
        $Query += $QueryEnd
        $Validation += ' -NotResolved '
	}
	Process
	{
		try
		{
            if (Invoke-Expression($Validation)){
                $CustomError = "Event already exists"
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
<#
    .SYNOPSIS

    Creates a new WRAD event.

    .DESCRIPTION

    Creates a new WRAD event in the Database. These events show the difference between the reference and the actual Active Directory.

    .PARAMETER SrcUserObjectGUID
    This parameter represents the actual source user.

    .PARAMETER SrcGroupObjectGUID
    This parameter represents the actual source group.

    .PARAMETER SrcRefUserObjectGUID
    This parameter represents the reference source user.

    .PARAMETER SrcRefGroupObjectGUID
    This parameter represents the reference source group.

    .PARAMETER DestGroupObjectGUID
    This parameter represents the actual destination group.

    .PARAMETER DestRefGroupObjectGUID
    This parameter represents the reference destination group.

    .PARAMETER EventType
    The type of the event (User not in Group, Group not in Group and so on...)

    .INPUTS

    None. You cannot pipe objects to New-WRADEvent.

    .OUTPUTS

    Nothing

    .EXAMPLE

    C:\PS> New-WRADEvent -SrcUserObjectGUID 54f3acba-39d1-4af8-863b-d32f682686dc -DestGroupObjectGUID cf6f0c47-cc6c-4108-8084-e6e5bfd0841b -EventType 4  

    #>
}