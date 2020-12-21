$ImageTemplateFile = ".\Image\JSON_Builds\Total_Image_Deployment.JSON"
$location = "West Europe"

Test-AzDeployment -Location $location -TemplateFile $ImageTemplateFile


New-AzDeployment -Location $location -Name "Total_Image_Deployment" -TemplateFile $ImageTemplateFile