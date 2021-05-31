Add-Type -assembly "Microsoft.Office.Interop.Outlook"
Add-type -assembly "System.Runtime.Interopservices"

$outlook = [Runtime.Interopservices.Marshal]::GetActiveObject('Outlook.Application')

$mapi = $outlook.GetNamespace("MAPI")

$inbox = $mapi.Folders("Shared Mailbox").Folders("Inbox")

$css_path = Resolve-Path "$PSScriptRoot\..\css\Email.css"
$html = $inbox.Items | Group-Object -Property Categories | Sort-Object Count -Descending | Select Count, Name | ConvertTo-Html -CssUri $css_path.Path | Out-String

$email          = $outlook.CreateItem(0)
$email.To       = "louie.bao@email.com"
$email.Subject  = "Example"
$email.HtmlBody = $html
$email.Attachments.Add("$PSScriptRoot\example.csv") | Out-Null
$email.Send()

<# Use the script below to create a scheduled task.

    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "C:\Dev\Check-Mailbox.ps1"'
    $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Monday, Tuesday, Wednesday, Thursday, Friday -At "12:00PM" # Requires the user to be logged on at that time.
    Register-ScheduledTask -TaskName "Check-Mailbox" -Action $action -Trigger $trigger

    Get-ScheduledTask "Check-Mailbox" | Get-ScheduledTaskInfo

    Unregister-ScheduledTask -TaskName "Check-Mailbox"
#>   
