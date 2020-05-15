Param
(
      [Parameter(Mandatory)]
      [string]$new_date
)

$new_date = $new_date -replace "-", ""
$date = [datetime]::ParseExact($new_date, "yyyyMMdd", $null)
$next_date = $date.AddDays(1)

$files = Get-ChildItem "$PSScriptRoot\*.csv"

$count = 1
foreach ($file in $files)
{
    (Get-Date).ToString("hh:mm tt") + ": $($file.BaseName) ($count/$($files.Length))"

    $old_date = ($file.BaseName -split "_")[-1].Substring(0, 8)

    Set-Content "$file.new" "`"AA`",$new_date,`"FAKE`",`"D`",`"S`""
    Select-String $file -Pattern ".+" | Select-Object -Skip 1 -ExpandProperty line | Add-Content "$file.new"

    Remove-Item $file -Force
    Rename-Item "$file.new" ("$file" -replace $old_date, $next_date.ToString("yyyyMMdd"))
    $count += 1
}
