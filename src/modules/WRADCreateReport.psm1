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
    #Get-WRADUser | Where-Object {-not $_.Enabled} | ConvertTo-Html -Property ObjectGUID,SAMAccountName,userPrincipalName,LastLogonTimestamp,DisplayName,CreatedDate,LastModifiedDate
    #

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Windows.Forms.DataVisualization

    $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $chart.Width = 400
    $chart.Height = 400
    $chart.Left = 20
    $chart.Top = 20

    $chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $chart.ChartAreas.Add($chartarea)

    [void]$chart.Series.Add("Data")

    $chart.Series["Data"].Points.DataBindXY(@("Dario","Beatli","Schlup","Nigatoni"),@(90,40,10,5))
    $chart.Series["Data"].ChartType= "Pie"
    $chart.Series["Data"]["PieLabelStyle"] = "Outside"
    $chart.Series["Data"]["PieLineColor"] = "Black"

    $chart.SaveImage("C:\TEMP\image.png", "PNG")
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