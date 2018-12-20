# import Reporting module
    try
	{
		Write-Verbose "Loading PS Module WRADCreateReport Class"
		Import-Module -Name ($PSScriptRoot+"\WRADCreateReport.psd1")
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}

$zipfile = (Write-WRADReport -users)[-1]

Expand-Archive -Path $zipfile -Destination $PSScriptRoot -Force
