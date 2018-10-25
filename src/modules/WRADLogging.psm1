# create filename (UTC)
$date = (get-date).ToUniversalTime().toString("yyyy-MM-dd")

# pass logtext and loglevel (0=INFO, 1=WARNING, 2=ERROR)
function Write-WRADLog{
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$logtext,

        [ValidateNotNullOrEmpty()]
        [int]$level=0
    )

    # import DB module
    try
	{
		Write-Verbose "Loading PS Module WRADDBCommands"
		Import-Module .\WRADDBCommands.psd1
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}

    # get log settings
    # $settings = Get-WRADSetting | Select-Object S
    # $external = 
    # $filepath = 
    # $syslogserver = 
    # $syslogprotocol = 

    if ($external -eq "syslog")
    {
        $sev = "Warning"
        if($level -eq 0)
	    {
		    $sev = "Informational"
	    }
	    if($level -eq 1)
	    {
		    $sev = "Warning"
	    }
	    if($level -eq 2)
	    {
		    $sev = "Critical"
		}		
        Send-SyslogMessage -Server $syslogserver -Message $logtext -Severity $sev -Facility local0
    }
    elseif ($external -eq "file")
    {
        $path = ""
        # create path if not exists
        try{
            $path = $filepath
            $parent = Split-Path -Path $filepath
            $null = New-Item -ItemType Directory -Force -Path $parent
        }
        catch{
            $path='C:\TEMP\WRAD\WRAD_'+$date
            Write-Verbose 'Path does not exist. Use C:\TEMP\WRAD\ instead'
        }

        # get logentry date (UTC)
        $logdate = (get-date).ToUniversalTime().toString("yyyy-MM-dd HH:mm:ss")

        if($level -eq 0)
	    {
		    $logtext = "[INFO] " + $logtext
		    $text = "["+$logdate+"] - " + $logtext
		    Write-Verbose $text
	    }
        if($level -eq 1)
	    {
		    $logtext = "[WARNING] " + $logtext
		    $text = "["+$logdate+"] - " + $logtext
		    Write-Verbose $text
	    }
        if($level -eq 2)
	    {
		    $logtext = "[ERROR] " + $logtext
		    $text = "["+$logdate+"] - " + $logtext
		    Write-Verbose $text
	    }

        try
        {
            # write to file
               $text >> $path
        }
        catch
        {
            Write-Error -Message $_.Exception.Message
        }
    }

    Write-WRADLog -logtext $logtext -level $level

    <#
    .SYNOPSIS

    Write Logentry to file

    .DESCRIPTION

    Write Logentry to file.

    .INPUTS

    1. Logtext
    2. Log-Severity (0=INFO, 1=WARNING, 2=ERROR)

    .OUTPUTS

    Writes Logs to file/database

    .EXAMPLE

    C:\PS> Write-WRADLog 'This is a testentry with severity WARNING' 1
    
    #>
}