#helper function to make text html-compatible (umlaute)
function toHtml([String] $text){
    $text = $text -replace "&", "&amp;"
    $text = $text -replace "ö", "&ouml;"
    $text = $text -replace "Ö", "&Ouml;"
    $text = $text -replace "ä", "&auml;"
    $text = $text -replace "Ä", "&Auml;"
    $text = $text -replace "Ü", "&Uuml;"
    $text = $text -replace "ü", "&uuml;"
    $text = $text -replace "<", "&lt;"
    $text = $text -replace ">", "&gt;"
    return $text
}
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
    Import-Module -Name ($PSScriptRoot+"\WRADEventText.psd1")
    # get events from DB and then convert eventID to actual message
    $events = Get-WRADEvent
    $texts = Get-WRADEventText -evs $events
    # get events that are newer than 14 days
    $14_days_date = (Get-Date).AddDays(-14)
    $14_days_events = Get-WRADEvent | Where-Object {$_.ResolvedDate -is [System.DBNull] -or $_.ResolvedDate -gt $14_days_date}
    $event_count = @{}
    # create values that are used to build the chart (number of events over time)
    # pretty much just check wheter a certain date was between created and resolved and then count up
    for($i=-14;$i -le 0;$i++){
        $str_date = (Get-Date -Date ((Get-Date).AddDays($i)) -UFormat "%Y%m%d").ToString()
        $event_count[$str_date] = 0
        foreach($e in $14_days_events){
            $cr = $e.CreatedDate
            $re = $e.ResolvedDate
            # if not yet resolved, just set it to current day +1
            if ($e.ResolvedDate -is [System.DBNull]){
                $re = (Get-Date).AddDays(1)
            }
            if ((Get-Date).AddDays($i) -gt $cr -and (Get-Date).AddDays($i) -le $re){
                $event_count[$str_date] += 1
            }
        }
    }
    
    # chart stuff...
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

    $chart.Series["Data"].Points.DataBindXY(($event_count.GetEnumerator() | sort -Property name).Name,($event_count.GetEnumerator() | sort -Property name).Value)
    $chart.Series["Data"].ChartType= "Line"
    $chart.Series["Data"]["PieLabelStyle"] = "Outside"
    $chart.Series["Data"]["PieLineColor"] = "Black"

    # return event texts and the created chart
    return ,@($texts,$chart)
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
    # get users from DB and save them to different variables according to when they last logged in
    $users = Get-WRADUser
    $disabled = $users | Where-Object {-not $_.Enabled}
    $users_0_30 = $users |Where-Object {$_.LastLogonTimestamp.ToString() -ne "" -and (New-TimeSpan -Start $_.LastLogonTimestamp -End (Get-Date)).Days -lt 30}
    $users_30_90 = $users |Where-Object {$_.LastLogonTimestamp.ToString() -ne "" -and (New-TimeSpan -Start $_.LastLogonTimestamp -End (Get-Date)).Days -ge 30 -and (New-TimeSpan -Start $_.LastLogonTimestamp -End (Get-Date)).Days -lt 90}
    $users_90_X = $users |Where-Object {$_.LastLogonTimestamp.ToString() -ne "" -and (New-TimeSpan -Start $_.LastLogonTimestamp -End (Get-Date)).Days -ge 90}
    $users_never = $users |Where-Object {$_.LastLogonTimestamp.ToString() -eq ""}
    # count the users per variable
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

    # Only add values to the chart that are not 0
    $names = New-Object System.Collections.Generic.List[System.Object]
    $values = New-Object System.Collections.Generic.List[System.Object]

    if ($users_0_30_c -ne 0){
        $names.add("< 30 days")
        $values.add($users_0_30_c)
    }
    if ($users_30_90_c -ne 0){
        $names.add("< 90 days")
        $values.add($users_30_90_c)
    }
    if ($users_90_X_c -ne 0){
        $names.add("> 90 days")
        $values.add($users_90_X_c)
    }
    if ($users_never_c -ne 0){
        $names.add("Never")
        $values.add($users_never_c)
    }

    $chart.Series["Data"].Points.DataBindXY($names,$values)
    $chart.Series["Data"].ChartType= "Pie"
    $chart.Series["Data"]["PieLabelStyle"] = "Outside"
    $chart.Series["Data"]["PieLineColor"] = "Black"
    # return the variables seperately and also the created chart
    return ,@($disabled, $users_30_90, $users_90_X, $users_never, $chart)
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
        Write-Verbose "Loading WRADLogging Module"
        Import-Module -Name ($PSScriptRoot+"\WRADLogging.psd1")
        Write-Verbose "Loading PDF Module"
		Add-Type -Path "$PSScriptRoot\itextsharp.dll"
        Import-Module "$PSScriptRoot\WRADPDF.psm1"
	}
	catch 
	{
		Write-Error -Message $_.Exception.Message
	}

    if ($events -and $users){
        Write-Error "Do not set both users and events."
        exit
    }

    # temp dir creation
    $new_guid = [System.Guid]::NewGuid()
    $target_path = "$env:Temp\$new_guid"

    New-Item -ItemType Directory -Path $target_path

    # user iTextSharp to create and open a PDF file
    $pdf = New-Object iTextSharp.text.Document
    Create-PDF -Document $pdf -File "$target_path\report.pdf" -TopMargin 20 -BottomMargin 20 -LeftMargin 20 -RightMargin 20 -Author "WRAD"
    $pdf.Open()

    # event report
    if ($events){
        # Use the function to get the needed information
        $evs = Get-WRADReportEvents
        $texts = $evs[0]
        $chart = $evs[1]
        # save chart to file
        $chart.SaveImage("$target_path\pic.png","PNG")
        # add text and image to pdf and html
        $report = "<!DOCTYPE html><head><title>Event Report</title></head><body><h1>Events</h1></body></html>"
        Add-Title -Document $pdf -Text "Event Report" -Color "black" -Centered
        #$report = $report -replace "</body>", "<h2>Number of Events</h2><img src='$target_path\pic.png'><h2>Current Events</h2></body>"
        $report = $report -replace "</body>", "<h2>Number of Events</h2><img src='pic.png'><h2>Current Events</h2></body>"
        Add-Title -Document $pdf -Text "Number of Events" -Color "blue" -FontSize 10
        Add-Image -Document $pdf -File "$target_path\pic.png"
        Add-Title -Document $pdf -Text "Current Events" -Color "blue" -FontSize 10
        foreach ($t in $texts){
            # use toHtml to handle umlaute
            $report = $report -replace "</body>", "<p>$(toHtml($t))</p></body>"
            Add-Text -Document $pdf -Text "$t"
        }
        $report | Out-File "$target_path\report.html"
    } # users report
    elseif ($users){
        # use the function to get the needed information
        $usr = Get-WRADReportUsers
        $disabled = $usr[0]
        $users_30_90 = $usr[1]
        $users_90_X = $usr[2]
        $users_never = $usr[3]
        $chart = $usr[4]
        # save chart to file
        $chart.SaveImage("$target_path\pic.png", "PNG")
        # add text and image to pdf and html
        Add-Title -Document $pdf -Text "User Report" -Color "black" -Centered
        Add-Title -Document $pdf -Text "Inactive Users" -FontSize 10
        Add-Image -Document $pdf -File "$target_path\pic.png"
        Add-Title -Document $pdf -Text "Disabled Users" -FontSize 10
        # PDF needs a dataset to write tables -> create list
        $set_to_write = New-Object System.Collections.Generic.List[System.Object]
        $set_to_write.Add("ObjectGUID")
        $set_to_write.Add("userPrincipalName")
        $set_to_write.Add("LastLogonTimestamp")
        $set_to_write.Add("DisplayName")
        foreach ($d in $disabled){
            $set_to_write.Add($d.ObjectGUID)
            $set_to_write.Add($d.userPrincipalName)
            $set_to_write.Add($d.LastLogonTimestamp)
            $set_to_write.Add($d.DisplayName)
        }
        Add-Table -Document $pdf -Dataset $set_to_write -Cols 4
        $report = $disabled | ConvertTo-Html -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName
        $report = $report -replace "<body>", "<body><h1>Disabled Users</h1>"
        #$report = $report -replace "</body>", "<h1>Inactive Users</h1><img src='$target_path\pic.png'></body>"
        $report = $report -replace "</body>", "<h1>Inactive Users</h1><img src='pic.png'></body>"
        $users_30_90_html = $users_30_90 | ConvertTo-HTML -Fragment -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName,Enabled
        $users_90_X_html = $users_90_X | ConvertTo-HTML -Fragment -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName,Enabled
        $users_never_html = $users_never | ConvertTo-HTML -Fragment -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName,Enabled
        $report = $report -replace "</body>", "<h2>30d &gt; Last Logon &lt; 90d</h2>$($users_30_90_html)</body>"
        $report = $report -replace "</body>", "<h2>90d &lt; Last Logon</h2>$($users_90_X_html)</body>"
        $report = $report -replace "</body>", "<h2>Never logged in</h2>$($users_never_html)</body>"
        Add-Title -Document $pdf -Text "30d > Last Logon < 90d" -FontSize 10
        $set_to_write = New-Object System.Collections.Generic.List[System.Object]
        $set_to_write.Add("ObjectGUID")
        $set_to_write.Add("userPrincipalName")
        $set_to_write.Add("LastLogonTimestamp")
        $set_to_write.Add("DisplayName")
        $set_to_write.Add("Enabled")
        foreach ($u in $users_30_90){
            $set_to_write.Add($u.ObjectGUID)
            $set_to_write.Add($u.userPrincipalName)
            $set_to_write.Add($u.LastLogonTimestamp)
            $set_to_write.Add($u.DisplayName)
            $set_to_write.Add($u.Enabled)
        }
        Add-Table -Document $pdf -Dataset $set_to_write -Cols 5
        Add-Title -Document $pdf -Text "90d > Last Logon" -FontSize 10
        $set_to_write = New-Object System.Collections.Generic.List[System.Object]
        $set_to_write.Add("ObjectGUID")
        $set_to_write.Add("userPrincipalName")
        $set_to_write.Add("LastLogonTimestamp")
        $set_to_write.Add("DisplayName")
        $set_to_write.Add("Enabled")
        foreach ($u in $users_90_X){
            $set_to_write.Add($u.ObjectGUID)
            $set_to_write.Add($u.userPrincipalName)
            $set_to_write.Add($u.LastLogonTimestamp)
            $set_to_write.Add($u.DisplayName)
            $set_to_write.Add($u.Enabled)
        }
        Add-Table -Document $pdf -Dataset $set_to_write -Cols 5
        Add-Title -Document $pdf -Text "Never Logged in" -FontSize 10
        $set_to_write = New-Object System.Collections.Generic.List[System.Object]
        $set_to_write.Add("ObjectGUID")
        $set_to_write.Add("userPrincipalName")
        $set_to_write.Add("LastLogonTimestamp")
        $set_to_write.Add("DisplayName")
        $set_to_write.Add("Enabled")
        foreach ($u in $users_never){
            $set_to_write.Add($u.ObjectGUID)
            $set_to_write.Add($u.userPrincipalName)
            $set_to_write.Add($u.LastLogonTimestamp)
            $set_to_write.Add($u.DisplayName)
            $set_to_write.Add($u.Enabled)
        }
        Add-Table -Document $pdf -Dataset $set_to_write -Cols 5
        $report | Out-File "$target_path\report.html"
    } # full report
    else {
        # get user stuff from function
        $usr = Get-WRADReportUsers
        $disabled = $usr[0]
        $users_30_90 = $usr[1]
        $users_90_X = $usr[2]
        $users_never = $usr[3]
        $usr_chart = $usr[4]
        # get event stuff from function
        $evs = Get-WRADReportEvents
        $texts = $evs[0]
        $evs_chart = $evs[1]
        Add-Title -Document $pdf -Text "Full Report" -Color "black" -Centered

        # do user stuff
        # additional comments in the above sections
        $usr_chart.SaveImage("$target_path\USRpic.png", "PNG")
        Add-Title -Document $pdf -Text "Inactive Users" -FontSize 10
        Add-Image -Document $pdf -File "$target_path\USRpic.png"
        Add-Title -Document $pdf -Text "Disabled Users" -FontSize 10
        $set_to_write = New-Object System.Collections.Generic.List[System.Object]
        $set_to_write.Add("ObjectGUID")
        $set_to_write.Add("userPrincipalName")
        $set_to_write.Add("LastLogonTimestamp")
        $set_to_write.Add("DisplayName")
        foreach ($d in $disabled){
            $set_to_write.Add($d.ObjectGUID)
            $set_to_write.Add($d.userPrincipalName)
            $set_to_write.Add($d.LastLogonTimestamp)
            $set_to_write.Add($d.DisplayName)
        }
        Add-Table -Document $pdf -Dataset $set_to_write -Cols 4
        $report = $disabled | ConvertTo-Html -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName
        $report = $report -replace "<body>", "<body><h1>Disabled Users</h1>"
        #$report = $report -replace "</body>", "<h1>Inactive Users</h1><img src='$target_path\USRpic.png'></body>"
        $report = $report -replace "</body>", "<h1>Inactive Users</h1><img src='USRpic.png'></body>"
        $users_30_90_html = $users_30_90 | ConvertTo-HTML -Fragment -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName,Enabled
        $users_90_X_html = $users_90_X | ConvertTo-HTML -Fragment -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName,Enabled
        $users_never_html = $users_never | ConvertTo-HTML -Fragment -Property ObjectGUID,userPrincipalName,LastLogonTimestamp,DisplayName,Enabled
        $report = $report -replace "</body>", "<h2>30d &gt; Last Logon &lt; 90d</h2>$($users_30_90_html)</body>"
        $report = $report -replace "</body>", "<h2>90d &lt; Last Logon</h2>$($users_90_X_html)</body>"
        $report = $report -replace "</body>", "<h2>Never logged in</h2>$($users_never_html)</body>"
        Add-Title -Document $pdf -Text "30d > Last Logon < 90d" -FontSize 10
        $set_to_write = New-Object System.Collections.Generic.List[System.Object]
        $set_to_write.Add("ObjectGUID")
        $set_to_write.Add("userPrincipalName")
        $set_to_write.Add("LastLogonTimestamp")
        $set_to_write.Add("DisplayName")
        $set_to_write.Add("Enabled")
        foreach ($u in $users_30_90){
            $set_to_write.Add($u.ObjectGUID)
            $set_to_write.Add($u.userPrincipalName)
            $set_to_write.Add($u.LastLogonTimestamp)
            $set_to_write.Add($u.DisplayName)
            $set_to_write.Add($u.Enabled)
        }
        Add-Table -Document $pdf -Dataset $set_to_write -Cols 5
        Add-Title -Document $pdf -Text "90d > Last Logon" -FontSize 10
        $set_to_write = New-Object System.Collections.Generic.List[System.Object]
        $set_to_write.Add("ObjectGUID")
        $set_to_write.Add("userPrincipalName")
        $set_to_write.Add("LastLogonTimestamp")
        $set_to_write.Add("DisplayName")
        $set_to_write.Add("Enabled")
        foreach ($u in $users_90_X){
            $set_to_write.Add($u.ObjectGUID)
            $set_to_write.Add($u.userPrincipalName)
            $set_to_write.Add($u.LastLogonTimestamp)
            $set_to_write.Add($u.DisplayName)
            $set_to_write.Add($u.Enabled)
        }
        Add-Table -Document $pdf -Dataset $set_to_write -Cols 5
        Add-Title -Document $pdf -Text "Never Logged in" -FontSize 10
        $set_to_write = New-Object System.Collections.Generic.List[System.Object]
        $set_to_write.Add("ObjectGUID")
        $set_to_write.Add("userPrincipalName")
        $set_to_write.Add("LastLogonTimestamp")
        $set_to_write.Add("DisplayName")
        $set_to_write.Add("Enabled")
        foreach ($u in $users_never){
            $set_to_write.Add($u.ObjectGUID)
            $set_to_write.Add($u.userPrincipalName)
            $set_to_write.Add($u.LastLogonTimestamp)
            $set_to_write.Add($u.DisplayName)
            $set_to_write.Add($u.Enabled)
        }
        Add-Table -Document $pdf -Dataset $set_to_write -Cols 5

        # do event stuff
        # additional comments in the above sections      
        $evs_chart.SaveImage("$target_path\EVSpic.png","PNG")
        $report = $report -replace "</body>", "<h1>Events</h1></body>"
        #$report = $report -replace "</body>", "<h2>Number of Events</h2><img src='$target_path\EVSpic.png'><h2>Current Events</h2></body>"
        $report = $report -replace "</body>", "<h2>Number of Events</h2><img src='EVSpic.png'><h2>Current Events</h2></body>"
        Add-Title -Document $pdf -Text "Current Events" -Color "blue" -FontSize 10
        foreach ($t in $texts){
            $report = $report -replace "</body>", "<p>$(toHtml($t))</p></body>"
            Add-Text -Document $pdf -Text "$t"
        }
        Add-Title -Document $pdf -Text "Number of Events" -Color "blue" -FontSize 10
        Add-Image -Document $pdf -File "$target_path\EVSpic.png"
        $report = $report -replace "</body>","<a href='.\report.pdf'>Download Report as PDF</a>"

        $report | Out-File "$target_path\report.html"
    }

    $pdf.Close()

    # create ZIP
    Compress-Archive -Path "$target_path\*" -CompressionLevel Fastest -DestinationPath "$target_path\report.zip"
    
    Write-WRADLog -logtext "Wrote Report Files to $target_path" -level 0

    return "$target_path\report.zip"

    <#
    .SYNOPSIS

    Creates Reports (HTML and PDF)

    .DESCRIPTION

    Gets the Events and Userdata from the Database and creates appropriate Reports in HTML or PDF.

    .PARAMETER users
    Create only User Report

    .PARAMETER events
    Create only Event Report

    .INPUTS

    None.

    .OUTPUTS

    In the last Position of the Output, there's a path to the ZIP file containing all needed resources for the report.

    .EXAMPLE

    C:\PS> $report = Write-WRADReport -users
    C:\PS> $zippath = $report[-1]
    C:\PS> $zippath
    C:\Users\WRADAD~2\AppData\Local\Temp\2\19373114-d81e-40c9-8971-1f8a1cc1d7c9\report.zip
    
    #>
}