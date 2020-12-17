$VMName = "WVD-Img-tst"
$RGName = "rg-$VMName"
$stopwatch = [system.diagnostics.stopwatch]::StartNew()

Remove-AzResourceGroup -Name "$RGName" -Force

$stopwatch.Stop()
Write-Output -InputObject $stopwatch.Elapsed.ToString('hh\:mm\:ss') 