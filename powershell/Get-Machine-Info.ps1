"`n`rPowershell Version: $($PSVersionTable.PSVersion.major).$($PSVersionTable.PSVersion.minor)"
"Free Diskspace: " + ((Get-WmiObject Win32_logicaldisk -Filter "DeviceID='C:'").FreeSpace / 1024 / 1024 / 1024).ToString('N0') + " GB"
"Free Memory: " + ((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1024).ToString('N0') + " MB"
