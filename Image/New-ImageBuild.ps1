Register-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
Get-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages | Where-Object RegistrationState -ne Registered | Register-AzResourceProvider

# Destination image resource group name
$imageResourceGroup = 'ImageBuilderRG'
# Azure region
$location = 'West Europe'
# Name of the image to be created
$imageTemplateName = 'Windows_Test_Image'
# Distribution properties of the managed image upon completion
$runOutputName = 'Dist_Windows_Test_Image'

$imageRoleDefName = "Azure Image Builder Image Def"
$identityName = "Windows_ImageBuild"

$myRoleImageCreationUrl = 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json'
$myRoleImageCreationPath = "$env:TEMP\myRoleImageCreation.json"

$myGalleryName = 'Windows_ImageBuild'
$imageDefName = 'Windows_ImageBuild'


# Your Azure Subscription ID
$subscriptionID = (Get-AzContext).Subscription.Id
Write-Output $subscriptionID

New-AzResourceGroup -Name $imageResourceGroup -Location $location


New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName

$identityNameResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId


Start-BitsTransfer -Source $myRoleImageCreationUrl -Destination $myRoleImageCreationPath

$Content = Get-Content -Path $myRoleImageCreationPath -Raw
$Content = $Content -replace '<subscriptionID>', $subscriptionID
$Content = $Content -replace '<rgName>', $imageResourceGroup
$Content = $Content -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
$Content | Out-File -FilePath $myRoleImageCreationPath -Force

New-AzRoleDefinition -InputFile $myRoleImageCreationPath

New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

New-AzGallery -GalleryName $myGalleryName -ResourceGroupName $imageResourceGroup -Location $location

$GalleryParams = @{
    GalleryName = $myGalleryName
    ResourceGroupName = $imageResourceGroup
    Location = $location
    Name = $imageDefName
    OsState = 'generalized'
    OsType = 'Windows'
    Publisher = 'VTM_Dev_01'
    Offer = 'Windows'
    Sku = 'Windows_WVD'
}
New-AzGalleryImageDefinition @GalleryParams

$SrcObjParams = @{
    SourceTypePlatformImage = $true
    Publisher = 'microsoftwindowsdesktop'
    Offer = 'office-365'
    Sku = '20h2-evd-o365pp'
    Version = 'latest'
}
$srcPlatform = New-AzImageBuilderSourceObject @SrcObjParams

$disObjParams = @{
    SharedImageDistributor = $true
    ArtifactTag = @{tag='dis-share'}
    GalleryImageId = "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup/providers/Microsoft.Compute/galleries/$myGalleryName/images/$imageDefName"
    ReplicationRegion = $location
    RunOutputName = $runOutputName
    ExcludeFromLatest = $false
}
$disSharedImg = New-AzImageBuilderDistributorObject @disObjParams

$ImgCustomParams = @{
    PowerShellCustomizer = $true
    CustomizerName = 'settingUpMgmtAgtPath'
    RunElevated = $false
    Inline = @("mkdir c:\\buildActions", "echo Azure-Image-Builder-Was-Here  > c:\\buildActions\\buildActionsOutput.txt")
}
$Customizer = New-AzImageBuilderCustomizerObject @ImgCustomParams


