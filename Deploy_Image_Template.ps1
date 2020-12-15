$idenityRG = "ManagedIdentities"
$idenityName = "WVD_ImageBuilder"
$subscriptionID = (Get-AzContext).Subscription.Id
$roledefFile = "$env:TEMP/AZRoleDef.Json"
$ImageTemplateFile = "ImageTemplate.JSON"

$imageResourceGroup = "Images"
$location = "West Europe"
$imageTemplateName = "Test_WVD_Image"


Add-Content -Path $roledefFile -Value @"
{
    "Name": "Azure WVD Image builder",
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
New-AzUserAssignedIdentity -Name "WVD_ImageBuilder" -ResourceGroupName $idenityRG

New-AzRoleDefinition -InputFile $roledefFile
Remove-Item -Path $roledefFile

##$idenityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $idenityRG -Name $idenityName).Id
##$ClientId = $(Get-AzUserAssignedIdentity -ResourceGroupName $idenityRG -Name $idenityName).ClientId
$idenityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $idenityRG -Name $idenityName).PrincipalId

New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName "Azure WVD Image builder" -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

New-AzResourceGroup -Name "$imageResourceGroup" -Location $Location 
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $ImageTemplateFile -imageTemplateName $imageTemplateName 

$RGs = Get-AzResourceGroup
$RGs | Where-Object {$_.ResourceGroupName -eq "IT_Images_Test_WVD_Image_928e78af-307c-47de-9aee-f8907a0298c3"} | Remove-AzResourceGroup -Force
$RGs | Where-Object {$_.ResourceGroupName -eq "Images"} | Remove-AzResourceGroup -Force

Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2020-02-14" -Action Run -Force

#Get Status of the Image Build and Query
##$resourcetowatch = Get-AzResource -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName
do {
    $status = (Get-AzResource -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName).Properties.lastRunStatus
    $status | Format-Table *
    Start-Sleep -Seconds 30
} while ($status.runState -eq "Running")

Register-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
do {
    $status = (Get-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview).RegistrationState
    $status | Format-Table *
    Start-Sleep -Seconds 30
} while ($status -eq "Registering")

(Get-AzResource –ResourceGroupName RG_WVD_AzureImageBuilder -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $ImageTemplateName).Properties.lastRunStatus