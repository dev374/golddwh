Write-Host "`n--> Creating (DEV) Pipelines & Triggers" -ForegroundColor Green

# Static pipelines 
$pl_config 			= $c.pipelines.pl_config
$pl_act_config 		= $c.pipelines.pl_act_config
$pl_act_archive		= $c.pipelines.template_act_archive
$pl_act_copydata	= $c.pipelines.template_act_copydata
$pl_act_log_start	= $c.pipelines.template_act_log_start
$pl_act_log_finish	= $c.pipelines.template_act_log_finish
$pl_act_log_error	= $c.pipelines.template_act_log_error
$pl_tem_start		= $c.pipelines.template_start
$pl_tem_ending		= $c.pipelines.template_ending
$tr_tem_datafile	= $c.triggers.template_trg_datafile
$ds_blob_file		= $c.datasets.template_blob_file
$ds_config 			= $c.datasets.ds_config
$linkedservicesql	= $c.datafactory.linkedservicesql

$path_pipelines 	= $(Join-Path $main $c.path.pipelines)
$path_datasets 		= $(Join-Path $main $c.path.datasets)
$path_triggers 		= $(Join-Path $main $c.path.triggers)
$path_templates 	= $(Join-Path $main $c.path.adftemplatespl)
$path_templates_ds 	= $(Join-Path $main $c.path.adftemplatesds)
$path_templates_tr  = $(Join-Path $main $c.path.adftemplatestr)
$path_config 		= $(Join-Path $main $c.path.config)

$global:activities  = Get-Content $(Join-Path $path_config $pl_act_config) | ConvertFrom-Json
$global:pipelines 	= Get-Content -Path $(Join-Path $path_config $pl_config) | ConvertFrom-Csv -Delimiter ';'
$global:datasets 	= Get-Content -Path $(Join-Path $path_config $ds_config) | ConvertFrom-Csv -Delimiter ';'
$c_blob_file 	    = Get-Content -Path $(Join-Path $path_templates_ds $ds_blob_file) 
$p_archive 			= Get-Content -Path $(Join-Path $path_templates $pl_act_archive) 
$p_copydata			= Get-Content -Path $(Join-Path $path_templates $pl_act_copydata) 
$p_logstart 		= Get-Content -Path $(Join-Path $path_templates $pl_act_log_start) 
$p_logfinish 		= Get-Content -Path $(Join-Path $path_templates $pl_act_log_finish) 
$p_logerror 		= Get-Content -Path $(Join-Path $path_templates $pl_act_log_error) 
$p_start			= Get-Content -Path $(Join-Path $path_templates $pl_tem_start) 
$p_ending			= Get-Content -Path $(Join-Path $path_templates $pl_tem_ending) 
$t_datafile  		= Get-Content -Path $(Join-Path $path_templates_tr $tr_tem_datafile) 

# Get existing datasets, pipelines and triggers
$global:getds = Get-AzDataFactoryV2Dataset -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$global:getpl = Get-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$global:gettr = Get-AzDataFactoryV2Trigger -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
 
$dsarray = @()
$plarray = @()
$trarray = @()

ForEach ($p in $getds.Name) {
	$dsarray += $p
}
ForEach ($p in $getpl.Name) {
	$plarray += $p
}
ForEach ($p in $gettr.Name) {
	$trarray += $p
}

#
### FUNCTIONS ###
#

function Create-DatasetJson-ForPipeline {

Param ([array]$row)
# v.1.0 initial, v.1.1 lilmited to file json (based on Create-DatasetJson)

	$createarray = @();
	
	$name = "$($row.inputs)"
	$dstemplate = $c_blob_file -replace "<datasetname>", "$name"
	$dstemplate = $dstemplate -replace "<linkedServiceName>", "$($row.linkedServiceName)"
	$dstemplate = $dstemplate -replace "<type>", "$($row.type)"
	$dstemplate = $dstemplate -replace "<filenameorfolder>", "$($row.filename)"
	$dstemplate = $dstemplate -replace "<locationtype>", "$($row.locationtype)"
	$dstemplate = $dstemplate -replace "<containername>", "$($row.containername)"
	$dstemplate = $dstemplate -replace "<flagfirstRowAsHeader>", "$($row.flagfirstRowAsHeader)"

	$json = $(Join-Path $path_datasets "$name.json")
	$createarray += $json
	$dstemplate > $json

	Write-Host "Dataset file: $name --> OK new JSON definition created in `
							  $json"
    return $json
}	

function Generate-Dataset-FromJson {
# v.1.0 initial

Param ([string]$jsonfile,
       [string]$datasetname,
       [bool]$overwrite)

    # Get existing datasets
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
			Write-Host "Dataset: $datasetname --> OK new dataset created"
	    } 
    }
}


# Create templates for each
$joinedObject = Foreach ($row in $pipelines) 
{
	$name = "$($row.pipelinename)"		
	$pl_template = "$p_start $p_logstart , $p_copydata , $p_archive , $p_logfinish $p_ending"	
		
	# Prepare tamplate in templates		
	$pl_template = $pl_template -replace "<filename>", "$($row.filename)"
	$pl_template = $pl_template -replace "<pipelinename>", "$name"
	$pl_template = $pl_template -replace "<sourceloaddatablob>", "$($row.containername)"
	$pl_template = $pl_template -replace "<copydatainputs>", "$($row.inputs)"
	$pl_template = $pl_template -replace "<copydataoutputs>", "$($row.outputs)"
	$pl_template = $pl_template -replace "<targetarchiveblob>", "$($activities.archive.targetarchiveblob)"
	$pl_template = $pl_template -replace "<statusstart>", "$($activities.logging.statusstart)"
	$pl_template = $pl_template -replace "<statusfinish>", "$($activities.logging.statusfinish)"		
	$pl_template = $pl_template -replace "<archiveinputs>", "$($row.inputs)"
	$pl_template = $pl_template -replace "<archiveoutputs>", "$($activities.archive.dataset)"
	$pl_template = $pl_template -replace "<loglinkedservicesql>", "$linkedservicesql"
	$pl_template = $pl_template -replace "<logstoredprocedurename>", "$($activities.logging.logstoredprocedurename)"
	$pl_template = $pl_template -replace "<logloadinderrordpendendon>", "$name"
	$pl_template = $pl_template -replace "                 ", "`n"

	# Generate pipeline & dataset definition
	$json_pl = $(Join-Path $path_pipelines "$name.json")
	$json_ds = $(Join-Path $path_datasets "$($row.inputs).json")
	Write-Host " 
	***   $name `
	" -ForegroundColor Cyan
		
	# Generate datasets
	$j = Create-DatasetJson-ForPipeline $row
    $d = Generate-Dataset-FromJson $json_ds $($row.inputs) -Overwrite 1

	# Create pipeline
	if($plarray -eq $name -and $overwrite) {
		Write-Host "Pipeline: $name --> NOK already exists" -ForegroundColor Red
	} else {
		
		$pl_template > $json_pl

		$newPipeline = New-AzDataFactoryV2Pipeline -ResourceGroupName $resourcegroupname `
		-DataFactoryName $datafactoryname -Name $name -Force `
		-File $json_pl
		
		Write-Host "Pipeline: $name --> OK new pipeline created" 
	} 		

}



