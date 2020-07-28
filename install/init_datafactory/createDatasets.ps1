# Static datasets 
$ds_config 			= $c.datasets.ds_config
$ds_blob_folder		= $c.datasets.template_blob_folder
$ds_blob_file		= $c.datasets.template_blob_file
$ds_sql				= $c.datasets.template_sql

$path_datasets 		= $c.path.datasets
$path_templates 	= $c.path.adftemplatesds
$path_config 		= $c.path.config
$global:datasets 	= Get-Content -Path $(Join-Path $path_config $ds_config) | ConvertFrom-Csv -Delimiter ';'
$global:c_blob_fold = Get-Content -Path $(Join-Path $path_templates $ds_blob_folder) 
$global:c_blob_file = Get-Content -Path $(Join-Path $path_templates $ds_blob_file) 
$global:c_sql  		= Get-Content -Path $(Join-Path $path_templates $ds_sql) 

# Get existing datasets
$global:getds = Get-AzDataFactoryV2Dataset -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$dsarray = @()
ForEach ($d in $getds.Name) {
	$dsarray += $d
}

# Create templates for each
$joinedObject = Foreach ($row in $datasets) 
{
	$createarray = @();

	# SQL type
	if ($row.typeid -eq 1) { 
		$name = "$($row.datasetname)"
		$dstemplate = $c_sql -replace "<datasetname>", "$($row.datasetname)"
		$dstemplate = $dstemplate -replace "<linkedServiceName>", "$($row.linkedServiceName)"
		$dstemplate = $dstemplate -replace "<type>", "$($row.type)"
		$dstemplate = $dstemplate -replace "<schema>", "$($row.schema)"
		$dstemplate = $dstemplate -replace "<tablename>", "$($row.tablename)"
		$dstemplate = $dstemplate -replace "<description>", "$($row.description)"
			
	# Blob file or Blob folder type or exit
	} else {

		if ($row.typeid -eq 2) { $dstemplate = $c_blob_file -replace "<datasetname>", "$($row.datasetname)" }
		elseif ($row.typeid -eq 3) { $dstemplate = $c_blob_fold -replace "<datasetname>", "$($row.datasetname)" }
		else {
			Write-Host "The dataset: typeid error. Exit"
			exit
		}
		$name = "$($row.datasetname)"
		$dstemplate = $dstemplate -replace "<linkedServiceName>", "$($row.linkedServiceName)"
		$dstemplate = $dstemplate -replace "<type>", "$($row.type)"
		$dstemplate = $dstemplate -replace "<filenameorfolder>", "$($row.filenameorfolder)"
		$dstemplate = $dstemplate -replace "<foldertype>", "$($row.foldertype)"		
		$dstemplate = $dstemplate -replace "<locationtype>", "$($row.locationtype)"
		$dstemplate = $dstemplate -replace "<containername>", "$($row.containername)"
		$dstemplate = $dstemplate -replace "<flagfirstRowAsHeader>", "$($row.flagfirstRowAsHeader)"

		$f = "$($row.containername)\$($row.filenameorfolder)\"
		$f = $f -replace "\\", "\"
	}  
	
	# For all types
	$json = $(Join-Path $path_datasets "$name.json")
	$createarray += $json
	$dstemplate > $json
	Write-Host "START dataset $name" 
		
	
	# Create 
	if($dsarray -eq $name) {
		Write-Host "SKIP dataset: $name already exists"
	} else {
		Write-Host "OK new dataset created: $name" 

		$newDataset = New-AzDataFactoryV2Dataset -ResourceGroupName $resourcegroupname `
		-DataFactoryName $datafactoryname -Name $name `
		-File $json
	} 
	
	
}

