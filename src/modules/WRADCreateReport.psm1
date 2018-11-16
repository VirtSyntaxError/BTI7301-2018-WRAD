function Write-WRADReport{
    # import DB module
    try
	{
		Write-Verbose "Loading PS Module WRADDBCommands and WRADEvent Class"
		Import-Module -Name ($PSScriptRoot+"\WRADDBCommands.psd1")
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}
    
    #NotEnabled
    Get-WRADUser | Where-Object {-not $_.Enabled} | ConvertTo-Html -Property ObjectGUID,SAMAccountName,userPrincipalName,LastLogonTimestamp,DisplayName,CreatedDate,LastModifiedDate
    #

    <#
    .SYNOPSIS

    Compare IST with SOLL (Reference with current)

    .DESCRIPTION

    Compare IST with SOLL (Reference with current)

    .INPUTS



    .OUTPUTS

    Fills the Ref table with data from RefNew

    .EXAMPLE

    C:\PS> Write-RefFromRefNew
    
    #>
}