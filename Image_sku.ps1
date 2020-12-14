$location = "west Europe"
$publisher = "microsoftwindowsdesktop"
$offer = "office-365"
$Sku = "20h2-evd-o365pp"


$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServer"
Get-AzVMImageSku -Location $location -PublisherName $publisher -Offer $offer