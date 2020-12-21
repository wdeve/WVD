$ImageTemplateFile = ".\Image\JSON_Builds\Total_Image_Deployment.JSON"
$location = "West Europe"

Test-AzSubscriptionDeployment  -Location $location -TemplateFile $ImageTemplateFile


New-AzDeployment -Location $location -Name "Total_Image_Deployment" -TemplateFile $ImageTemplateFile

New-AzSubscriptionDeployment  -Location $location -Name "Total_Image_Deployment" -TemplateFile $ImageTemplateFile
