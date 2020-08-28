# Create Data Factory

write-host "
Creating a new DF..."

# Create DF
$df = New-AzDataFactoryV2 -ResourceGroupName $resourceGroupName `
    -Name $datafactoryname `
    -Location $location
