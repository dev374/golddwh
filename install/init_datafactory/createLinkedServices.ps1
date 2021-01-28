
# Variables - set the resource group name, location, servername, database and allowed IP range
$pathadflinkedservices = $(Join-Path $main $c.path.adflinkedservices)
$linkedserviceblob = $c.datafactory.linkedserviceblob
$linkedservicesql = $c.datafactory.linkedservicesql
$linkedservicejsonext = $c.datafactory.linkedservicejsonext

#
### FUNCTIONS ###
#

function Create-LinkedService {

Param ([string]$ls_name,
	   [string]$file_template,
	   [bool]$overwrite)

	if(-not($lsarray -like $ls_name) -or $overwrite) {
		$msg = "Linked service: OK new linked service created $ls_name" 

		# Create linked service
		$newLinkedService = Set-AzDataFactoryV2LinkedService `
		-ResourceGroupName $resourceGroupName `
		-DataFactoryName $datafactoryname `
		-Name $ls_name -Force `
		-File $file_template | Format-List

	} else {
		$msg = "Linked service: $ls_name already exists"
	} 	
	return $msg
}
 
# Get existing
$getls = Get-AzDataFactoryV2LinkedService -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$lsarray = @()
ForEach ($l in $getls.Name) {
	$lsarray += $l
}

# Generate blob ls
	$ls_blob_template = '{
		"name": "<lsName>",
		"type": "Microsoft.DataFactory/factories/linkedservices",
		 "properties": {
			"annotations": [],
			"type": "AzureBlobStorage",
			"typeProperties": {
				"connectionString": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=<accountName>;AccountKey=<accountKey>"
			}
		}
	}' 

	$ls_blob_connstr = "DefaultEndpointsProtocol=https;AccountName=<accountName>;AccountKey=<accountKey>;EndpointSuffix=core.windows.net"
	$ls_blob_template = $ls_blob_template -replace "<lsName>", $linkedserviceblob
	$ls_blob_template = $ls_blob_template -replace "<accountName>", $storagename
	$ls_blob_template = $ls_blob_template -replace "<accountKey>", $storagekey

	$file_blob = Join-Path $pathadflinkedservices $($linkedserviceblob+$linkedservicejsonext)
	$ls_blob_template > $file_blob

	$a = Create-LinkedService $linkedserviceblob $file_blob 0
	echo $a

# Generate sql ls
	$ls_sql_template = '{
		"name": "<lsName>",
		"type": "Microsoft.DataFactory/factories/linkedservices",
		"properties": {
			"annotations": [],
			"type": "AzureSqlDatabase",
			"typeProperties": {
				"connectionString": "integrated security=False;encrypt=True;connection timeout=30;data source=<sqlServer>.database.windows.net;initial catalog=<databaseName>;user id=<adminLogin>;password=<adminPass>"
			}
		}
	}'

	$ls_sql_template = $ls_sql_template -replace "<lsName>", $linkedservicesql
	$ls_sql_template = $ls_sql_template -replace "<sqlServer>", $servername
	$ls_sql_template = $ls_sql_template -replace "<databaseName>", $databaseName 
	$ls_sql_template = $ls_sql_template -replace "<adminLogin>", $adminLogin
	$ls_sql_template = $ls_sql_template -replace "<adminPass>", $adminPass

# Create LS sql
	$file_sql = Join-Path $pathadflinkedservices $($linkedservicesql+$linkedservicejsonext)
	$ls_sql_template > $file_sql
	$b = Create-LinkedService $linkedservicesql $file_sql 0
	echo $b
	
