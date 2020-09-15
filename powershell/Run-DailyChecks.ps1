foreach ($sql_file in Get-ChildItem "$PSScriptRoot\*.sql")
{
    "  $($sql_file.FullName)"
    $result = Invoke-SqlCmd -ServerInstance "servername" -QueryTimeout 180 -InputFile $sql_file.FullName -OutputAs "DataTables"
    $output = $sql_file.FullName + ".table"

    Set-Content $output "<div style='display:inline-block;margin:10px'>"
    Add-Content $output "<h3>$($sql_file.BaseName)</h3>"
    Add-Content $output "<table border='1' cellpadding='5px'>"
    Add-Content $output "<caption>$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</caption>"

    Add-Content $output "<tr>"
    foreach ($col in $result.Columns)
    {
        Add-Content $output "<th>$($col.ColumnName)</th>"
    }
    Add-Content $output "</tr>"

    foreach ($row in $result.Rows)
    {
        Add-Content $output "<tr>"
        foreach ($col in $result.Columns)
        {
            if ($($row[$($col.ColumnName)]) -match "^-?\d+.*$")
            {
                Add-Content $output "<td style='text-align:right'>"
            }
            else
            {
                Add-Content $output "<td>"
            }

            Add-Content $output $($row[$($col.ColumnName)])
            Add-Content $output "</td>"
        }
        Add-Content $output "</tr>"
    }

    Add-Content $output "</table></div>"
}

$dailycheck_file = "$PSScriptRoot\Dailychecks.html"

Set-Content $dailycheck_file "<head><link rel='stylesheet' href='DailyChecks.css'></head><body>"
Add-Content $dailycheck_file "<div style='float:right'>Run Date: $(Get-Date -Format 'ddd, dd MMM yyyy HH:mm')</div>"

"`r`nConcatenating results..."
foreach ($html_file in Get-ChildItem "$PSScriptRoot\*.table")
{
    "  $($html_file.FullName)"

    $data = Get-Content $html_file.FullName | Out-String
    [System.IO.File]::AppendAllText($dailycheck_file, $data)
}

Add-Content $dailycheck_file "</body>"
