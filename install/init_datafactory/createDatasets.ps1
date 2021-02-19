Write-Host "`n--> Creating (DEV) Datasets" -ForegroundColor Green

# Static datasets 
$ds_config 			= $c.datasets.ds_config
$ds_blob_folder		= $c.datasets.template_blob_folder
$ds_blob_file		= $c.datasets.template_blob_file
$ds_sql				= $c.datasets.template_sql
$ds_overwrite 		= $c.datasets.overwrite

$path_datasets 		= $(Join-Path $main $c.path.datasets)
$path_templates 	= $(Join-Path $main $c.path.adftemplatesds)
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

#
### FUNCTIONS ###
#

function Create-DatasetJson {

Param ([array]$row)
# v.1.0 initial

	$createarray = @();

	# SQL type
	if ($row.typeid -eq 1) { 
		$name = "$($row.datasetname)"
		$dstemplate = $c_sql -replace "<datasetname>", "$($row.datasetname.Lower)"
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

	Write-Host "Dataset file: $name --> OK new JSON definition created in $json"
    return $json
}	

function Generate-Dataset-FromJson {
# v.1.0 initial

Param ([string]$jsonfile,
       [string]$datasetname,
       [bool]$Overwrite)

    # Get existing datasets
    $getds = Get-AzDataFactoryV2Dataset -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
    $dsarray = @()
    ForEach ($d in $getds.Name) {
	    $dsarray += "$d.json"
    }

    $datasetname = $datasetname -replace ".json", ""

	if($overwrite -eq $true) {
		$newDataset = Set-AzDataFactoryV2Dataset -Name $datasetname -DefinitionFile $jsonfile `
		-ResourceGroupName $resourcegroupname -DataFactoryName $datafactoryname -Force
		
		Write-Host "Dataset: $datasetname --> OK new dataset created (overwritten)"
    } else {

	    if($dsarray -eq $datasetname) {
			Write-Host "Dataset: $datasetname --> NOK already exists" -ForegroundColor Red
	    }  else {		
			$newDataset = Set-AzDataFactoryV2Dataset -Name $datasetname -DefinitionFile $jsonfile `
			-ResourceGroupName $resourcegroupname -DataFactoryName $datafactoryname

			Write-Host "Dataset: $datasetname --> OK new dataset created"
	    } 
    }
}

#
### MAIN PROGRAM ###
#

$datasetObject = ForEach ($row in $datasets) 
{
    $j = Create-DatasetJson $row
}

$filelist = Get-ChildItem -Path $path_datasets -File | Where-Object { ($_.Name -like '*.json') }

$generateObject = ForEach ($row in $filelist) 
{
    $d = Generate-Dataset-FromJson $(Join-Path $path_datasets $row.Name) $($row.Name) -Overwrite $ds_overwrite
}

