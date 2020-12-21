$idenityRG = "ManagedIdentities"
$idenityName = "WVD_ImageBuilder"
$subscriptionID = (Get-AzContext).Subscription.Id
$roledefFile = "$env:TEMP/AZRoleDef.Json"
$ImageTemplateFile = "Image\JSON_Builds\ImageTemplate_ManagedImageD.JSON"

$imageResourceGroup = "Images"
$location = "West Europe"
$imageTemplateName = "Test_WVD_Image"


Add-Content -Path $roledefFile -Value @"
{
    "Name": "Azure Image builder",
    "IsCustom": true,
    "Description": "Image Builder access to create resources for the image build, you should delete or split out as appropriate",
    "Actions": [
        "Microsoft.Compute/galleries/read",
        "Microsoft.Compute/galleries/images/read",
        "Microsoft.Compute/galleries/images/versions/read",
        "Microsoft.Compute/galleries/images/versions/write",
        "Microsoft.Compute/images/write",
        "Microsoft.Compute/images/read",
        "Microsoft.Compute/images/delete"
    ],
    "NotActions": [],
    "AssignableScopes": [
        "/subscriptions/$subscriptionID/resourceGroups/$idenityRG",
        "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup",
    ]
}
"@
New-AzResourceGroup -Name "$imageResourceGroup" -Location $Location -Force

New-AzUserAssignedIdentity -Name "WVD_ImageBuilder" -ResourceGroupName $idenityRG

New-AzRoleDefinition -InputFile $roledefFile
Remove-Item -Path $roledefFile
Start-Sleep -Seconds 20
##$idenityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $idenityRG -Name $idenityName).Id
##$ClientId = $(Get-AzUserAssignedIdentity -ResourceGroupName $idenityRG -Name $idenityName).ClientId
$idenityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $idenityRG -Name $idenityName).PrincipalId

New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName "Azure Image builder" -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $ImageTemplateFile -imageTemplateName $imageTemplateName 
Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2020-02-14" -Action Run -Force

#Get Status of the Image Build and Query
##$resourcetowatch = Get-AzResource -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName
Write-Host -NoNewline "Waiting  "
do {
    $status = (Get-AzResource -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName).Properties.lastRunStatus
    Write-Host -NoNewline "."
    Start-Sleep -Seconds 30
} while ($status.runState -eq "Running")
Write-Host -ForegroundColor Green "`nFinally done"
(Get-AzResource -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName).Properties.lastRunStatus


break 



Test-AzResourceGroupDeployment -ResourceGroupName Temp -TemplateFile $ImageTemplateFile -imageTemplateName $imageTemplateName 





###Extra conde
Register-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
do {
    $status = (Get-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview).RegistrationState
    $status | Format-Table *
    Start-Sleep -Seconds 30
} while ($status -eq "Registering")

(Get-AzResource -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName).Properties.lastRunStatus
Get-AzImageBuilderTemplate -ImageTemplateName  $imageTemplateName -ResourceGroupName $imageResourceGroup | Select-Object -ExpandProperty LastRunStatus| Select-Object -ExpandProperty Message


Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages | Where-Object RegistrationState -ne Registered | Register-AzResourceProvider

New-AzImageBuilderTemplate -Source





Get-AzRoleAssignment -RoleDefinitionName "Azure Image builder" | Remove-AzRoleAssignment
Remove-AzUserAssignedIdentity -Name "WVD_ImageBuilder" -ResourceGroupName $idenityRG -Force
Remove-AzRoleDefinition -Name "Azure Image builder" -Force

#Envoirment cleanup
$RGs = Get-AzResourceGroup
$RGs | Where-Object {$_.ResourceGroupName -like "IT_Images_Test_WVD_Image"} | Remove-AzResourceGroup -Force
$RGs | Where-Object {$_.ResourceGroupName -eq "Images"} | Remove-AzResourceGroup -Force
##Remove-AzResourceGroup ImageBuilderRG -Force