function Set-Module{
    param (
        [Parameter(Mandatory)]
        [String]$ModuleName
    )
    Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
    #If the module isn't installed install module
    if(-not(Get-InstalledModule $ModuleName -ErrorAction SilentlyContinue)){Install-Module -Name $ModuleName -Scope AllUsers -Force}
    #If the module isn't imported import module
    if(-not(Get-Module $ModuleName )){Import-Module $ModuleName -Force}
    #Verify the installation of the module
    if(Get-Module $ModuleName -ErrorAction SilentlyContinue){Write-Output "The module $ModuleName is imported and installed"}
    else{
        Write-Host -ForegroundColor Red -Object "Error: something went wrong and the module isn't imported"
        exit
    }
}
function Remove-Pester{
    #Remove the default Pester install
    $modulePath = "C:\Program Files\WindowsPowerShell\Modules\Pester"
    if (-not (Test-Path $modulePath)) {
        "There is no Pester folder in $modulePath, doing nothing."
        break
    }
    takeown /F $modulePath /A /R
    icacls $modulePath /reset
    icacls $modulePath /grant Administrators:'F' /inheritance:d /T
    Remove-Item -Path $modulePath -Recurse -Force -Confirm:$false
}
#test
Remove-Pester

Set-Module -ModuleName Az 
Set-Module -ModuleName AzureAd
Set-Module -ModuleName Pester
Set-Module -ModuleName AzureAd
Set-Module -ModuleName MSOnline
Set-Module -ModuleName MicrosoftTeams
Set-Module -ModuleName PartnerCenter
Set-Module -ModuleName SqlServer
Set-Module -ModuleName SharePointPnPPowerShellOnline