$url = "https://aka.ms/fslogix_download"
$output = "FSlogix.zip"
Start-BitsTransfer -Source $url -Destination $PSScriptroot\$output
(New-Object System.Net.WebClient).DownloadFile($url, $output)
Expand-Archive -LiteralPath $output -DestinationPath "$PSScriptroot\FSLogix" -erroraction Silentlycontinue
& "$PSScriptroot/FSLogix/x64/Release/FSLogixAppsSetup.exe" /install /quiet /norestart