
# Create a blank database with given performance level
$db = Get-AzSQLDatabase -ServerName $serverName -ResourceGroupName $resourceGroupName 

	if(-not($db.DatabaseName -like $databaseName)) {
		# Create a blank database with given performance level
		$database = New-AzSqlDatabase -ResourceGroupName $resourceGroupName `
			-ServerName $serverName `
			-DatabaseName $databaseName `
			-RequestedServiceObjectiveName $objective 
		Write-Host "OK. New Database is $databaseName"
	} else {
		Write-Host "Database $databaseName exists"		
	}	


