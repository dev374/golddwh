
# Variables - set the resource group name, location, servername, database and allowed IP range
$global:datafactoryname = $c.datafactory.datafactoryname

write-host "
Creating a new DF..."

# Create DF
$df = New-AzDataFactoryV2 -ResourceGroupName $resourceGroupName `
    -Name $datafactoryname `
    -Location $location
