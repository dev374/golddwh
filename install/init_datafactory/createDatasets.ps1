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
$getds = Get-AzDataFactoryV2Dataset -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$dsarray = @()
ForEach ($d in $getds.Name) {
	$dsarray += $d
}

# Create templates for each
$joinedObject = Foreach ($row in $datasets) 
{
	$createarray = @();

	if ($row.typeid -eq 2) {
		$name = "$($row.datasetname)"
		$dstemplate = $c_sql -replace "<datasetname>", "$($row.datasetname)"
		$dstemplate = $dstemplate -replace "<description>", "$($row.description)"
		$dstemplate = $dstemplate -replace "<linkedServiceName>", "$($row.linkedServiceName)"
		$dstemplate = $dstemplate -replace "<type>", "$($row.type)"
		$dstemplate = $dstemplate -replace "<schema>", "$($row.schema)"
		$dstemplate = $dstemplate -replace "<tablename>", "$($row.tablename)"
		
		$json = $(Join-Path $path_datasets "$($row.datasetname).json")
		$createarray += $json
		$dstemplate > $json
		
		# Create 
		if($dsarray -eq $name) {
			Write-Host "The dataset: $name already exists"
		} else {
			Write-Host "OK new dataset is $name" 
			
			$newDataset = New-AzDataFactoryV2Dataset -ResourceGroupName $resourcegroupname `
			-DataFactoryName $datafactoryname -Name $name `
			-File $json
		} 
		
	}
	
		
}


<# v1. working ok
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
#>


