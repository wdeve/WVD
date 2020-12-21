$Location = "West Europe"
$VMName = "WVD-Img-tst"
$RGName = "rg-$VMName"

$RGTemplateFile = "TestVM\RG.JSON"
$VMTemplateFile = "TestVM\WVD_Image_TestVM.json"

$stopwatch = [system.diagnostics.stopwatch]::StartNew()

$PublicIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content


function New-AzVMDeployment {
    param(
        [parameter(Mandatory)]
        [string]$VMName,
        [parameter(Mandatory)]
        [string]$RGName,
        [parameter(Mandatory)]
        [string]$VMTemplateFile,
        [parameter(Mandatory)]
        [string]$PublicIP
    )
    $VMDeploymentOutput = New-AzResourceGroupDeployment -Name "Deploy_$VMName" -TemplateFile $VMTemplateFile -ResourceGroupName $RGName -VMName $VMName -PublicIP $PublicIP
    if ($VMDeploymentOutput.ProvisioningState -eq "Succeeded") {
        Write-Host -ForegroundColor Green "[+] VM deployment success!!!"
    }
    else {
        Write-Host -ForegroundColor Red "[-] VM deployment failed"
    }
}

function New-AzRGDeployment{
    param(
        [parameter(Mandatory)]
        [string]$RGName,
        [parameter(Mandatory)]
        [string]$RGTemplateFile,
        [parameter(Mandatory)]
        [string]$Location
    )
    $RGDeploymentOutput = New-AzDeployment -Name "Deploy_$RGName" -Location $Location -TemplateFile $RGTemplateFile -RGName $RGName 
    if ($RGDeploymentOutput.ProvisioningState -eq "Succeeded") {
        Write-Host -ForegroundColor Green "[+] RG deployment success!!!"
        $psobect = [PSCustomObject]@{Success = $true}
    }
    else {
        Write-Host -ForegroundColor Red "[-] RG deployment failed"
        $psobect = [PSCustomObject]@{Success = $false}
    }
    return $psobect
}

$RGCheck = Get-AzResourceGroup -Name $RGName -Location $Location -ErrorAction SilentlyContinue
if (-not($RGCheck.ProvisioningState -eq "Succeeded")){
    $RGDeployment = New-AzRGDeployment -RGName $RGName -RGTemplateFile $RGTemplateFile -Location $Location
    if ($RGDeployment.Success) {
        New-AzVMDeployment -VMName $VMName -RGName $RGName -VMTemplateFile $VMTemplateFile -PublicIP $PublicIP
    }
}
else {
    Write-Host -ForegroundColor Green "[+] RG Already exists"
    New-AzVMDeployment -VMName $VMName -RGName $RGName -VMTemplateFile $VMTemplateFile -PublicIP $PublicIP
}

$stopwatch.Stop()
Write-Output -InputObject $stopwatch.Elapsed.ToString('hh\:mm\:ss') 