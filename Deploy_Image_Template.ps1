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
        "/subscriptions/$subscriptionID/resourceGroups/$idenityRG"
    ]
}
"@

New-AzRoleDefinition -InputFile $roledefFile

$idenityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $idenityRG -Name $idenityName).Id
$ClientId = $(Get-AzUserAssignedIdentity -ResourceGroupName $idenityRG -Name $idenityName).ClientId
$idenityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $idenityRG -Name $idenityName).PrincipalId

New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName "Azure WVD Image builder" -Scope "/subscriptions/$subscriptionID/resourceGroups/$idenityRG"

New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $ImageTemplateFile -imageTemplateName $imageTemplateName 

New-AzResourceGroup -Name "$imageResourceGroup" -Location $Location 

$RGs = Get-AzResourceGroup
$RGs | Where-Object {$_.ResourceGroupName -eq "IT_Images_Test_WVD_Image_e9b6a6dc-ce67-4c20-ab84-cc64f2798c2e"} | Remove-AzResourceGroup -Force
$RGs | Where-Object {$_.ResourceGroupName -eq "Images"} | Remove-AzResourceGroup -Force