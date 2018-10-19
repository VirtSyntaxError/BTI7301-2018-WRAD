# create filename (UTC)
$date = (get-date).ToUniversalTime().toString("yyyy-MM-dd")
$file = ("WRAD_LOG_" + $date + ".log")

# pass logtext, loglevel (0=INFO, 1=WARNING, 2=ERROR) and optionally a path
function Write-WRADLog{
    Param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$logtext,

    [ValidateNotNullOrEmpty()]
    [int]$level=0, 

    [ValidateScript({[System.IO.Path]::IsPathRooted($_)})]
    [string]$path='C:\TEMP\WRAD'
    )
    # create path if not exists
    try{
        $null = New-Item -ItemType Directory -Force -Path $path
    }
    catch{
        $path='C:\TEMP\WRAD'
    }
    # get logentry date (UTC)
	$logdate = (get-date).ToUniversalTime().toString("yyyy-MM-dd HH:mm:ss")
    $logfile = $path + "\" + $file
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
        $text >> $logfile
    }
    catch
    {
    	Write-Error -Message $_.Exception.Message
        break
    }
    <#
    .SYNOPSIS

    Write Logentry to file

    .DESCRIPTION

    Write Logentry to file.

    .INPUTS

    1. Logtext
    2. Log-Severity (0=INFO, 1=WARNING, 2=ERROR)
    3. Path to Directory (Optional, default = C:\TEMP\WRAD)

    .OUTPUTS

    Writes Log to file

    .EXAMPLE

    C:\PS> Write-WRADLog 'This is a testentry with severity WARNING' 1 C:\PATH\to\dir
    
    #>
}