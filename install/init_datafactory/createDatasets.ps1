# Static datasets 
$file_mtd_blob		= "\metadata_blob.txt"
$file_mtd_sql		= "\metadata_sql.txt"
$file_definitions 	= "\config_datasets_blob.csv"
$path_datasets 		= $c.path.datasets
$path_templates 	= $c.path.adftemplatesds
$path_config 		= $c.path.config
$global:ds_definitions 	= Get-Content -Path $(Join-Path $path_config $file_definitions) | ConvertFrom-Csv -Delimiter ';'
$global:ds_metadata = Get-Content -Path $(Join-Path $path_templates $file_mtd_blob) 

# Variables - set the config_datasets.csv
$datasetname = $c.datasets.datasetname
$linkedServiceName = $linkedserviceblob #$c.datasets.linkedServiceName
$type = $c.datasets.type
$location = $c.datasets.location
$filename = $c.datasets.filename
$containername = $c.datasets.containername
$columnsdelimiter = $c.datasets.columnsdelimiter
$flagfirstRowAsHeader = $c.datasets.flagfirstRowAsHeader

# Get existing
$getds = Get-AzDataFactoryV2Dataset -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$dsarray = @()
ForEach ($d in $getds.Name) {
	$dsarray += $d
	echo $d
}

# Templated datasets create
$createarray = @('dst_sql_in','src_blob_in')
ForEach ($c in $createarray) {
	if($dsarray -like $c) {
		echo "The linked service: $c already exists"
	} else {
		echo "OK new dataset is $c" 
		$f = $(Join-Path $path_templates $c) + ".json"
		
		# Create 
		$newDataset = New-AzDataFactoryV2Dataset -ResourceGroupName $resourcegroupname `
        -DataFactoryName $datafactoryname -Name $c `
        -File $f
	} 
}


<#
	if($dsarray -like $linkedserviceblob) {
		echo "The linked service: $linkedserviceblob already exists"
	} else {
		echo "OK new dataset is $linkedserviceblob" 

		# Create 
		$newDataset = New-AzDataFactoryV2Dataset -ResourceGroupName "ADF" `
        -DataFactoryName "WikiADF" -Name "DAWikipediaClickEvents" `
        -File "C:\\samples\\WikiSample\\DA_WikipediaClickEvents.json"

	} 

#>