
# Variables - set the resource group name, location, servername, database and allowed IP range
$global:resourceGroupName = $c.server.resourcegroupname
$global:serverName = $c.server.servername
$global:databaseName = $c.database.databaseName
$global:objective = $c.database.objective


# Create a blank database with given performance level
$db = Get-AzSQLDatabase -ServerName $serverName -ResourceGroupName $resourceGroupName 
$rgnarray = @()
ForEach ($r in $rgn.resourcegroupname) {
	$rgnarray += $r
}
if($rgnarray -like $resourceGroupName) {
	echo "The resourcegroup: $resourceGroupName already exists"
} else {
	echo "OK new resourcegroup is $resourceGroupName" 

    # Create resourcegroupname
	$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
}


# Create a blank database with given performance level
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName $objective 
