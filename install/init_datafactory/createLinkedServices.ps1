
# Variables - set the resource group name, location, servername, database and allowed IP range
<#
$global:resourceGroupName = $c.server.resourcegroupname
$global:datafactoryname = $c.datafactory.datafactoryname
$global:storagename = $c.storage.storagename
#>
$storagekey = $c.storage.storagekey
$pathadflinkedservices = $c.path.adflinkedservices
$linkedserviceblob = $c.datafactory.linkedserviceblob
$linkedservicesql = $c.datafactory.linkedservicesql
$linkedservicejsonext = $c.datafactory.linkedservicejsonext
$encrypted_credential = "ew0KICAiVmVyc2lvbiI6ICIyMDE3LTExLTMwIiwNCiAgIlByb3RlY3Rpb25Nb2RlIjogIktleSIsDQogICJTZWNyZXRDb250ZW50VHlwZSI6ICJQbGFpbnRleHQiLA0KICAiQ3JlZGVudGlhbElkIjogIkRBVEFGQUNUT1JZNjQwNTIxMjA0X2UzYmFlZDNkLTNjNzAtNDEzYy05YTU2LTkzZjk5YTlhNDI1YSINCn0="
 
# Get existing
$getls = Get-AzDataFactoryV2LinkedService -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$lsarray = @()
ForEach ($l in $getls.Name) {
	$lsarray += $l
	echo $l
}

# Generate blob ls
	$ls_blob_template = '{
		"name": "<lsName>",
		"type": "Microsoft.DataFactory/factories/linkedservices",
		 "properties": {
			"annotations": [],
			"type": "AzureBlobStorage",
			"typeProperties": {
				"connectionString": "DefaultEndpointsProtocol=https;AccountName=<accountName>;AccountKey=<accountKey>;EndpointSuffix=core.windows.net"
			}
		}
	}' 

	$ls_blob_template = $ls_blob_template -replace "<lsName>", $linkedserviceblob
	$ls_blob_template = $ls_blob_template -replace "<accountName>", $storagename
	$ls_blob_template = $ls_blob_template -replace "<accountKey>", $storagekey

	$file_blob = Join-Path $pathadflinkedservices $($linkedserviceblob+$linkedservicejsonext)
	$ls_blob_template > $file_blob

	if($lsarray -like $linkedserviceblob) {
		echo "The linked service: $linkedserviceblob already exists"
	} else {
		echo "OK new linked service is $linkedserviceblob" 

		# Create linked service
		$newLinkedService = Set-AzDataFactoryV2LinkedService `
		-ResourceGroupName $resourceGroupName `
		-DataFactoryName $datafactoryname `
		-Name $linkedserviceblob `
		-File $file_blob | Format-List

	} 

# Generate sql ls
	$ls_sql_template = '{
		"name": "<lsName>",
		"type": "Microsoft.DataFactory/factories/linkedservices",
		"properties": {
			"annotations": [],
			"type": "AzureSqlDatabase",
			"typeProperties": {
				"connectionString": "integrated security=False;encrypt=True;connection timeout=30;data source=<sqlServer>.database.windows.net;initial catalog=<databaseName>;user id=<adminLogin>",
				"encryptedCredential": "<encrypted_credential>"
			}
		}
	}'

	$ls_sql_template = $ls_sql_template -replace "<lsName>", $linkedservicesql
	$ls_sql_template = $ls_sql_template -replace "<sqlServer>", $servername
	$ls_sql_template = $ls_sql_template -replace "<databaseName>", $databaseName 
	$ls_sql_template = $ls_sql_template -replace "<adminLogin>", $adminLogin
	$ls_sql_template = $ls_sql_template -replace "<encrypted_credential>", $encrypted_credential

	$file_sql = Join-Path $pathadflinkedservices $($linkedservicesql+$linkedservicejsonext)
	$ls_sql_template > $file_sql

	if($lsarray -like $linkedservicesql) {
		echo "The linked service: $linkedservicesql already exists"
	} else {
		echo "OK new linked service is $linkedservicesql" 

		# Create linked service
		$newLinkedService = Set-AzDataFactoryV2LinkedService `
		-ResourceGroupName $resourceGroupName `
		-DataFactoryName $datafactoryname `
		-Name $linkedservicesql `
		-File $file_sql | Format-List
	} 


