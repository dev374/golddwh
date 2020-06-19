# Connect-AzAccount
Select-AzSubscription -Subscription "Visual Studio Professional Subscription"

# New database?
$databaseName = "dbdw-etl"
$objective = "S0"

# Variables with DevNet IP
$resourceGroupName = "resourcegroup01"
$location = "West Europe"
$serverName = "sqlsrvdw"
$startIp = "188.122.18.4"
$endIp = "188.122.18.255"

# Create a blank database with an B performance level
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName $objective 
