$date_folder = (Get-Date).ToString("yyyy-MM-dd")
$date_folder_path = Join-Path "C:\Temp" $date_folder

if (!(Test-Path $date_folder_path))
{
    mkdir $date_folder_path
}

Get-ChildItem "C:\Temp\20[1-9][0-9]-[0-1][0-9]-[0-3][0-9]" | ? { ((Get-Date) - $_.LastWriteTime).Days -gt 30 } | Remove-Item -Recurse -Force
