function Import-WRADcsv
{
	[cmdletbinding()] # needed for the Verbose function
	Param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ })]
        [String]$csvPath,
        [Parameter(Mandatory=$true)]
        [ValidateSet('Users','Groups')]
		[string]$Type
	)
<#
    try 
	{
		Write-Verbose "Loading PS Module WRADDBCommands";
		Import-Module $PSScriptRoot\WRADDBCommands.psd1
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
    }#>
    

    try
    {
        $csvData = Import-Csv -Path:$csvPath
        Write-Host $csvData
    }
    catch
    {
        Write-Error -Message $_.Exception.Message
    }
}
# Example Function Call
#Import-WRADcsv -csvPath "C:\Code\BFH.WRAD\doc\ImportTemplateUser.csv" -Type "Users"