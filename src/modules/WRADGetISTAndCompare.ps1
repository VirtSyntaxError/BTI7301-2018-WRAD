# import Reporting module
    try
	{
		Write-Verbose "Loading PS Module WRADCreateReport Class"
		Import-Module -Name ($PSScriptRoot+"\WRADGetIST.psd1")
        Import-Module -Name ($PSScriptRoot+"\WRADUpdateReferenceObjectGUID.psd1")
        Import-Module -Name ($PSScriptRoot+"\WRADSOLLISTVergleich.psd1")
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}

Write-WRADISTtoDB

Update-WRADReferenceObjectGUID

Invoke-WRADSOLLISTVergleich
