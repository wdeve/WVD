$url = "https://aka.ms/fslogix_download"
$output = "FSlogix.zip"
#Dowload FSlogiix
Start-BitsTransfer -Source $url -Destination $PSScriptroot\$output
#Unzip the zip file
Expand-Archive -LiteralPath $output -DestinationPath "$PSScriptroot\FSLogix" -erroraction Silentlycontinue
#Install FSLogix
& "$PSScriptroot/FSLogix/x64/Release/FSLogixAppsSetup.exe" /install /quiet /norestart