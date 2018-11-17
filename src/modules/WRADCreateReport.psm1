function Get-WRADReportEvents{
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
}
function Get-WRADReportUsers{
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
    $users = Get-WRADUser
    $disabled = $users | Where-Object {-not $_.Enabled}
    $users_0_30 = $users |Where-Object {$_.LastLogonTimestamp.ToString() -ne "" -and (New-TimeSpan -Start $_.LastLogonTimestamp -End (Get-Date)).Days -lt 30}
    $users_30_90 = $users |Where-Object {$_.LastLogonTimestamp.ToString() -ne "" -and (New-TimeSpan -Start $_.LastLogonTimestamp -End (Get-Date)).Days -ge 30 -and (New-TimeSpan -Start $_.LastLogonTimestamp -End (Get-Date)).Days -lt 90}
    $users_90_X = $users |Where-Object {$_.LastLogonTimestamp.ToString() -ne "" -and (New-TimeSpan -Start $_.LastLogonTimestamp -End (Get-Date)).Days -ge 90}
    $users_never = $users |Where-Object {$_.LastLogonTimestamp.ToString() -eq ""}
    $users_0_30_c = ($users_0_30 | measure).Count
    $users_30_90_c = ($users_30_90 | measure).Count
    $users_90_X_c = ($users_90_X | measure).Count
    $users_never_c = ($users_never | measure).Count
    # create chart for inactive users
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

    $chart.Series["Data"].Points.DataBindXY(@("< 30 days","< 90 days","> 90 days","Never"),@($users_0_30_c,$users_30_90_c,$users_90_X_c,$users_never_c))
    $chart.Series["Data"].ChartType= "Pie"
    $chart.Series["Data"]["PieLabelStyle"] = "Outside"
    $chart.Series["Data"]["PieLineColor"] = "Black"

    return @($disabled, $users_30_90, $users_90_X, $users_never, $chart)
}
function Write-WRADReport{
    Param
    (
		[ValidateNotNullOrEmpty()]
		[Switch]$events,

        [ValidateNotNullOrEmpty()]
		[Switch]$users
    )
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

    if ($events -and $users){
        Write-Error "Do not set both users and events."
        exit
    }
    # event report
    if ($events){
        exit
    } # users report
    elseif ($users){
        $usr = Get-WRADReportUsers
        $disabled = $usr[0]
        $users_30_90 = $usr[1]
        $users_90_X = $usr[2]
        $users_never = $usr[3]
        $chart = $usr[4]
        $report = $disabled | ConvertTo-Html -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName
        $report = $report -replace "<body>", "<body><h1>Disabled Users</h1>"
        $report = $report -replace "</body>", "<h1>Inactive Users</h1><img src='C:\TEMP\pic.png'></body>"
        $chart.SaveImage("C:\TEMP\pic.png", "PNG")
        $users_30_90_html = $users_30_90 | ConvertTo-HTML -Fragment -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName,Enabled
        $users_90_X_html = $users_90_X | ConvertTo-HTML -Fragment -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName,Enabled
        $users_never_html = $users_never | ConvertTo-HTML -Fragment -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName,Enabled
        $report = $report -replace "</body>", "<h2>30d > Last Logon <90d$($users_30_90_html)</body>"
        Write-Host $report
        
    } # full report
    else {
        exit
    }

    <#
    .SYNOPSIS

    

    .DESCRIPTION

    

    .INPUTS



    .OUTPUTS

    

    .EXAMPLE

    C:\PS> 
    
    #>
}