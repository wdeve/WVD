$Uri = "https://github.com/microsoft/terminal/releases/download/v1.4.3243.0/Microsoft.WindowsTerminal_1.4.3243.0_8wekyb3d8bbwe.msixbundle"
$File = "$env:TEMP/WindowsTerminalInstaller.msixbundle"
#Download the windows terminal package
Invoke-WebRequest -Uri $Uri -OutFile $File
#Install the windows terminal package
Add-AppPackage .\WindowsTerminalInstaller.msixbundle