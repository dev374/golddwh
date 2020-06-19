# Connect-AzAccount
Select-AzSubscription -Subscription "Visual Studio Professional Subscription"
Register-AzResourceProvider -ProviderNamespace Microsoft.DataFactory

# New database?
$databaseName = "dbdw-etl"
$objective = "S0"

# Variables with DevNet IP
$resourceGroupName = "resourcegroup01"
$location = "West Europe"
$name = "datafactorydwv2"

write-host "
Perform these operations in the following order:
Create a data factory.
Create linked services.
Create datasets.
Create a pipeline.

Creating a new DF..."

# Create 
$df = New-AzDataFactoryV2  -ResourceGroupName $resourceGroupName `
    -Name $name `
    -Location $location
