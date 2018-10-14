Set-StrictMode -Version Latest

$null = [System.Reflection.Assembly]::LoadWithPartialName('MySql.Data')
$BuiltinParameters = @("ErrorAction","WarningAction","Verbose","ErrorVariable","WarningVariable","OutVariable","OutBuffer","Debug")

function Connect-WRADDatabase {
    $PasswordPlain = "ktX4xRb7qxSw6oPctx"
    $Password = ConvertTo-SecureString -AsPlainText $PasswordPlain -Force
    $Username = "wradadmin"
    $Server = "localhost"
    $Port = "3306"
    $Database = "WRAD"
    $SSLMode = "none"

    $Credentials =  New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $Username,$Password

    $ConnectionString = "server=$Server;port=$Port;uid=$Username;pwd=$PasswordPlain;database=$Database;SSLMode=$SSLMode"
    [MySql.Data.MySqlClient.MySqlConnection]$Connection = New-Object MySql.Data.MySqlClient.MySqlConnection($ConnectionString)

    $Global:WRADDBConnection = $Connection

    Write-Verbose "Connecting to Database";
    $Connection.Open()

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
    Param
	(
        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$SAMAccountName,

        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$UserPrincipalName,

        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$DisplayName,

        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID,

        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Disabled,

        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Expired


	)
	begin
	{
        $Query = 'SELECT * FROM WRADUser';

        $FirstParameter = $true;

        $PSBoundParameters.Keys | ForEach {
        if ($BuiltinParameters -notcontains $_) {
            $Value = Get-Variable -Name $_ -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop

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
		
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADUser";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
    <#
    .SYNOPSIS

    Gets all users.

    .DESCRIPTION

    Gets all users which actually exist in the database. These are the fetched users from the Active Directory.
    The Output does not conaint any deleted users.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of an user.

    .PARAMETER UserPrincipalName
    Specifies the UserPrincipalName of an user.
    
    .PARAMETER DisplayName
    Specifies the DisplayName of an user.

    .PARAMETER ObjectGUID
    Specifies the Globally Unique Identifier of an user.

    .PARAMETER Disabled
    Specifies if an user is disabled.

    .PARAMETER Expired
    Specifies if an user is expired.

    .INPUTS

    None. You cannot pipe objects to Get-WRADUser.

    .OUTPUTS

    System.Array. Get-WRADUser returns all parameters from the user table in an array.

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
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$SAMAccountName,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$DistinguishedName,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[DateTime]$LastLogonTimestamp,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$UserPrincipalName,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$DisplayName,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Disabled,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$Description,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$Expired


	)
	begin
	{
        if($Disabled){
            $EnabledValue = 0
        } else {
            $EnabledValue = 1
        }

        if($Expired){
            $ExpiredValue = 1
        } else {
            $ExpiredValue = 0
        }
    
        $Query = 'INSERT INTO WRADUser (`ObjectGUID`, `SAMAccountName`, `DistinguishedName`, `userPrincipalName`, `DisplayName`, `Enabled`, `Expired`'
        $QueryValue = ') VALUES("'+$ObjectGUID+'", "'+$SAMAccountName+'", "'+$DistinguishedName.Replace('"','\"')+'", "'+$UserPrincipalName+'", "'+$DisplayName+'", '+$EnabledValue+', '+$ExpiredValue
        $QueryEnd = ')'

        if($LastLogonTimestamp){
            $Timestamp = $LastLogonTimestamp.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
            $Query += ', `LastLogonTimestamp`'
            $QueryValue += ', "'+$Timestamp+'"'
        }
        if($Description){
            $Query += ', `Description`'
            $QueryValue += ', "'+$Description.Replace('"','\"')+'"'
		}

        $Query += $QueryValue
        $Query += $QueryEnd
	}
	Process
	{
		try
		{
            Write-Verbose "Checking for already existent user";
            if((Get-WRADUser -ObjectGUID $ObjectGUID) -ne $null){
                $CustomError = "Duplicate entry for ObjectGUID "+$ObjectGUID
                throw($CustomError) 
            }
            
			Write-Verbose "Invoking INSERT SQL Query on table WRADUser";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
    <#
    .SYNOPSIS

    Creates new user.

    .DESCRIPTION

    Creates new user in the database.

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

    None. You cannot pipe objects to New-WRADUser.

    .OUTPUTS

    Nothing. New-WRADUser returns an error if something is wrong.

    .EXAMPLE

    C:\PS> New-WRADUser -ObjectGUID d9dl998-03jlasd9-lasd99 -SAMAccountName testuser -DistinguishedName 'CN="testuser",CN="example",CN="local"' -UserPrincipalName test.user -DisplayName "testuser" -Description "Testuser for WRAD" -LastLogonTimestamp $timestamp

    #>
}

function Update-WRADUser {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$ObjectGUID,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$SAMAccountName,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$DistinguishedName,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[DateTime]$LastLogonTimestamp,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$UserPrincipalName,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$DisplayName,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Bool]$Enabled,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$Description,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Bool]$Expired


	)
	begin
	{
        $Query = 'UPDATE WRADUser SET '
        $QueryEnd = ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
        $QueryValue = @()

        if($PSBoundParameters.ContainsKey('Enabled')){
            if($Enabled -eq $true ){
                $QueryValue += '`Enabled` = 1'
            } else {
                $QueryValue += '`Enabled` = 0'
            }
        }

        if($PSBoundParameters.ContainsKey('Expired')){
            if($Expired -eq $true ){
                $QueryValue += '`Expired` = 1'
            } else {
                $QueryValue += '`Expired` = 0'
            }
        }

        if($LastLogonTimestamp){
            $Timestamp = $LastLogonTimestamp.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
            $QueryValue += '`LastLogonTimestamp` = "'+$Timestamp+'"'
        }

        if($Description){
            $QueryValue += '`Description` = "'+$Description.Replace('"','\"')+'"'
		}

        if($DistinguishedName){
            $QueryValue += '`DistinguishedName` = "'+$DistinguishedName.Replace('"','\"')+'"'
		}

        if($SAMAccountName){
            $QueryValue += '`SAMAccountName` = "'+$SAMAccountName+'"'
		}

        if($UserPrincipalName){
            $QueryValue += '`UserPrincipalName` = "'+$UserPrincipalName+'"'
		}

        if($DisplayName){
            $QueryValue += '`DisplayName` = "'+$DisplayName+'"'
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

            Write-Verbose "Checking is user exists";
            if((Get-WRADUser -ObjectGUID $ObjectGUID) -eq $null){
                $CustomError = "User $ObjectGUID does not exist"
                throw($CustomError) 
            }
            
			Write-Verbose "Invoking Update SQL Query on table WRADUser";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
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
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID
	)
	begin
	{
        $Query = 'DELETE FROM WRADUser WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
	}
	Process
	{
		try
		{
            Write-Verbose "Checking is user exists";
            if((Get-WRADUser -ObjectGUID $ObjectGUID) -eq $null){
                $CustomError = "User $ObjectGUID does not exist"
                throw($CustomError) 
            }

			Write-Verbose "Invoking DELETE SQL Query on table WRADUser";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	End
	{
	}
}

function Get-WRADGroup {
    Param
	(
        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$SAMAccountName,

        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$CommonName,

        [Parameter()]
        [ValidateSet('ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP','ADS_GROUP_TYPE_UNIVERSAL_GROUP')]
		[string]$GroupType,

        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID,
        
        [Parameter()]
		[ValidateSet('Security','Distribution')]
		[String]$GroupTypeSecurity

	)
	begin
	{
        $Query = "SELECT * FROM WRADGroup";

        $FirstParameter = $true;

        $PSBoundParameters.Keys | ForEach {
        if ($BuiltinParameters -notcontains $_) {
            $Value = Get-Variable -Name $_ -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop

            if($FirstParameter){
                $Query += ' WHERE `'+$_+'` = "'+$Value+'" '
                $FirstParameter = $false
            } else {
                $Query += ' AND `'+$_+'` = "'+$Value+'" '
            }
        }
}
		
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	End
	{
	}
}

function New-WRADGroup {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$SAMAccountName,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$CommonName,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$DistinguishedName,

        [Parameter(Mandatory=$true)]
        [ValidateSet('ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP','ADS_GROUP_TYPE_UNIVERSAL_GROUP')]
		[string]$GroupType,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$Description,
        
        [Parameter(Mandatory=$true)]
		[ValidateSet('Security','Distribution')]
		[string]$GroupTypeSecurity

	)
	begin
	{
        $Query = 'INSERT INTO WRADGroup (`ObjectGUID`, `SAMAccountName`, `DistinguishedName`, `CommonName`'
        $QueryValue = ') VALUES("'+$ObjectGUID+'", "'+$SAMAccountName+'", "'+$DistinguishedName.Replace('"','\"')+'", "'+$CommonName+'"'
        $QueryEnd = ')'

        if($Description){
            $Query += ', `Description`'
            $QueryValue += ', "'+$Description.Replace('"','\"')+'"'
		}

        $Query += $QueryValue
        $Query += $QueryEnd		
	}
	Process
	{
		try
		{
            Write-Verbose "Checking for already existent group";
            if((Get-WRADGroup -ObjectGUID $ObjectGUID) -ne $null){
                $CustomError = "Duplicate entry for ObjectGUID "+$ObjectGUID
                throw($CustomError) 
            }

			Write-Verbose "Invoking INSERT SQL Query on table WRADGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	<#
    .SYNOPSIS

    Creates a new group.

    .DESCRIPTION

    Creates a new group in the database with the given parameters.

    .PARAMETER SAMAccountName
    Specifies the SAMAccountName of the group.

    .PARAMETER CommonName
    Specifies the CommonName of the group.

    .PARAMETER DistinguishedName
    Specifies the DistinguishedName of the group. Like CN="testgroup",CN="example",CN="local"

    .PARAMETER GroupType
    Specifies the GroupType of the group. This should be 'ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP' or 'ADS_GROUP_TYPE_UNIVERSAL_GROUP'.
    
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

    C:\PS> New-WRADGroup -ObjectGUID d9dl998-03jlasd6-lasd11 -SAMAccountName "Domain Powerusers" -CommonName "Domain Powerusers" -DistinguishedName 'CN="Domain Powerusers",CN="example",CN="local"' -GroupTypeSecurity Security -GroupType ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP

    #>
}

function Update-WRADGroup {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$SAMAccountName,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$CommonName,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$DistinguishedName,

        [Parameter(Mandatory=$false)]
        [ValidateSet('ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP','ADS_GROUP_TYPE_UNIVERSAL_GROUP')]
		[string]$GroupType,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$Description,
        
        [Parameter(Mandatory=$false)]
		[ValidateSet('Security','Distribution')]
		[string]$GroupTypeSecurity


	)
	begin
	{
        $Query = 'UPDATE WRADGroup SET '
        $QueryEnd = ' WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
        $QueryValue = @()

        if($Description){
            $QueryValue += '`Description` = "'+$Description.Replace('"','\"')+'"'
		}

        if($DistinguishedName){
            $QueryValue += '`DistinguishedName` = "'+$DistinguishedName.Replace('"','\"')+'"'
		}

        if($SAMAccountName){
            $QueryValue += '`SAMAccountName` = "'+$SAMAccountName+'"'
		}

        if($CommonName){
            $QueryValue += '`CommonName` = "'+$CommonName+'"'
		}

        if($GroupType){
            $QueryValue += '`GroupType` = "'+$GroupType+'"'
		}

        if($GroupTypeSecurity){
            $QueryValue += '`GroupTypeSecurity` = "'+$GroupTypeSecurity+'"'
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

            Write-Verbose "Checking is group exists";
            if((Get-WRADGroup -ObjectGUID $ObjectGUID) -eq $null){
                $CustomError = "Group $ObjectGUID does not exist"
                throw($CustomError) 
            }
            
			Write-Verbose "Invoking Update SQL Query on table WRADGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
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
    Specifies the GroupType of the group. This should be 'ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP' or 'ADS_GROUP_TYPE_UNIVERSAL_GROUP'.
    
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
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectGUID
	)
	begin
	{
        $Query = 'DELETE FROM WRADGroup WHERE `ObjectGUID` = "'+$ObjectGUID+'"'
	}
	Process
	{
		try
		{
            Write-Verbose "Checking is group exists";
            if((Get-WRADGroup -ObjectGUID $ObjectGUID) -eq $null){
                $CustomError = "Group $ObjectGUID does not exist"
                throw($CustomError) 
            }

			Write-Verbose "Invoking DELETE SQL Query on table WRADGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	End
	{
	}
}

function Get-WRADGroupOfUser {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$UserObjectGUID,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$GroupObjectGUID
	)
	begin
	{
        $Query = 'SELECT * FROM WRADUserGroup WHERE `UserObjectGUID` = "'+$UserObjectGUID+'"';	
        
        if($GroupObjectGUID){
            $Query += ' AND `GroupObjectGUID` = "'+$GroupObjectGUID+'"'
		}
        	
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADUserGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	End
	{
	}
}

function New-WRADGroupOfUser {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$UserObjectGUID,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$GroupObjectGUID

	)
	begin
	{
        $Query = 'INSERT INTO WRADUserGroup (`UserObjectGUID`, `GroupObjectGUID`) VALUES ("'+$UserObjectGUID+'", "'+$GroupObjectGUID+'")'
	}
	Process
	{
		try
		{
            Write-Verbose "Checking for already existent user to group mapping";
            if((Get-WRADGroupOfUser -UserObjectGUID $UserObjectGUID -GroupObjectGUID $GroupObjectGUID) -ne $null){
                $CustomError = "Duplicate entry for UserObjectGUID "+$UserObjectGUID+" and GroupObjectGUID "+$GroupObjectGUID
                throw($CustomError) 
            }

			Write-Verbose "Invoking INSERT SQL Query on table WRADUserGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	End
	{
	}
}

function Remove-WRADGroupOfUser {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$UserObjectGUID,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$GroupObjectGUID
	)
	begin
	{
        $Query = 'DELETE FROM WRADUserGroup WHERE `UserObjectGUID` = "'+$UserObjectGUID+'" AND `GroupObjectGUID` = "'+$GroupObjectGUID+'"'
	}
	Process
	{
		try
		{
            Write-Verbose "Checking if user is in group";
            if((Get-WRADGroupOfUser -UserObjectGUID $UserObjectGUID -GroupObjectGUID $GroupObjectGUID ) -eq $null){
                $CustomError = "User $UserObjectGUID and Group $GroupObjectGUID connection does not exist"
                throw($CustomError) 
            }

			Write-Verbose "Invoking DELETE SQL Query on table WRADUserGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	End
	{
	}
}

function Get-WRADGroupOfGroup {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ChildGroupObjectGUID,

        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ParentGroupObjectGUID
	)
	begin
	{
        $Query = 'SELECT * FROM WRADGroupGroup WHERE `ChildGroupObjectGUID` = "'+$ChildGroupObjectGUID+'"';		

        if($ParentGroupObjectGUID){
            $Query += ' AND `ParentGroupObjectGUID` = "'+$ParentGroupObjectGUID+'"'
		}
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking INSERT SQL Query on table WRADGroupGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	End
	{
	}
}

function New-WRADGroupOfGroup {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ChildGroupObjectGUID,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ParentGroupObjectGUID

	)
	begin
	{
        $Query = 'INSERT INTO WRADGroupGroup (`ChildGroupObjectGUID`, `ParentGroupObjectGUID`) VALUES ("'+$ChildGroupObjectGUID+'", "'+$ParentGroupObjectGUID+'")'
	}
	Process
	{
		try
		{
            Write-Verbose "Checking for already existent group to group mapping";
            if((Get-WRADGroupOfGroup -ChildGroupObjectGUID $ChildGroupObjectGUID -ParentGroupObjectGUID $ParentGroupObjectGUID) -ne $null){
                $CustomError = "Duplicate entry for UserObjectGUID "+$ChildGroupObjectGUID+" and GroupObjectGUID "+$ParentGroupObjectGUID
                throw($CustomError) 
            }

			Write-Verbose "Invoking INSERT SQL Query on table WRADGroupGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	End
	{
	}
}

function Remove-WRADGroupOfGroup {
    Param
	(
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ChildGroupObjectGUID,

        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$ParentGroupObjectGUID
	)
	begin
	{
        $Query = 'DELETE FROM WRADGroupGroup WHERE `ChildGroupObjectGUID` = "'+$ChildGroupObjectGUID+'" AND `ParentGroupObjectGUID` = "'+$ParentGroupObjectGUID+'"'
	}
	Process
	{
		try
		{
            Write-Verbose "Checking if group is in group";
            if((Get-WRADGroupOfGroup -ChildGroupObjectGUID $ChildGroupObjectGUID -ParentGroupObjectGUID $ParentGroupObjectGUID) -eq $null){
                $CustomError = "Group $ChildGroupObjectGUID and Group $ParentGroupObjectGUID connection does not exist"
                throw($CustomError) 
            }

			Write-Verbose "Invoking DELETE SQL Query on table WRADGroupGroup";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
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
			$Error[0];
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
			$Error[0];
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
			$Error[0];
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
			$Error[0];
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
			$Error[0];
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
			$Error[0];
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
	)
	begin
	{
        $Query = 'SELECT * FROM WRADSetting';		
	}
	Process
	{
		try
		{
			Write-Verbose "Invoking SELECT SQL Query on table WRADSetting";
			Invoke-MariaDBQuery -Query $Query -ErrorAction Stop;
		}
		catch
		{
			$Error[0];
			break
		}
	}
	End
	{
	}
}

Connect-WRADDatabase

Export-ModuleMember Get-*
Export-ModuleMember Update-*
Export-ModuleMember New-*
Export-ModuleMember Remove-*

#Get-WRADUser -Disabled -Verbose | foreach { write-host $_.DisplayName }

#Get-WRADGroup -GroupType ADS_GROUP_TYPE_GLOBAL_GROUP -GroupTypeSecurity Security -Verbose

#Get-WRADGroupOfUser -ObjectGUID testid -Verbose | foreach { get-wradgroup -ObjectGUID $_.GroupObjectGUID }

#Get-WRADGroupOfGroup -ObjectGUID testid -Verbose

#Get-WRADUser | foreach { Get-WRADHistoryOfUser -ObjectGUID $_.ObjectGUID -Verbose}

#Get-WRADGroup | foreach { Get-WRADHistoryOfGroup -ObjectGUID $_.ObjectGUID -Verbose }

#write-host -ForegroundColor red "Get all deleted groups"

#Get-WRADDeletedGroup -Verbose

#write-host -ForegroundColor red "Get all deleted users"

#Get-WRADDeletedUser -Verbose

#write-host -ForegroundColor red "Get all deleted groups of user with GUID testid"

#Get-WRADDeletedGroupOfUser -ObjectGUID testid -Verbose

#write-host -ForegroundColor red "Get all deleted groups of group with GUID testid"

#Get-WRADDeletedGroupOfGroup -ObjectGUID testid -Verbose

#write-host -ForegroundColor red "Get all settings"

#Get-WRADSetting -Verbose

#write-host -ForegroundColor red "Create new user Philipp"
#$timestamp = (get-date).AddDays(-30)
#New-WRADUser -ObjectGUID testid10 -SAMAccountName philipp -DistinguishedName "CN=philipp,CN=example,CN=local" -UserPrincipalName phillip.koefer -DisplayName "Phillip Köfer" -Expired -Description "Phillip Testuser" -LastLogonTimestamp $timestamp -Verbose

#write-host -ForegroundColor red "Create new group Domain Powerusers"
#New-WRADGroup -ObjectGUID testid20 -SAMAccountName "Domain Powerusers" -CommonName "Domain Powerusers" -DistinguishedName 'CN="Domain Powerusers",CN="example",CN="local"' -GroupTypeSecurity Security -GroupType ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP -Verbose

#write-host -ForegroundColor red "Attach group testid20 to user testid10"
#New-WRADGroupOfUser -UserObjectGUID testid10 -GroupObjectGUID testid20 -Verbose

#write-host -ForegroundColor red "Attach group testid20 to group testid2"
#New-WRADGroupOfGroup -ChildGroupObjectGUID testid20 -ParentGroupObjectGUID testid2 -Verbose