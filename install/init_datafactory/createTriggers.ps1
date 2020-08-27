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

$path_pipelines 	= $c.path.pipelines
$path_datasets 		= $c.path.datasets
$path_triggers 		= $c.path.triggers
$path_templates 	= $c.path.adftemplatespl
$path_templates_ds 	= $c.path.adftemplatesds
$path_templates_tr  = $c.path.adftemplatestr
$path_config 		= $c.path.config

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

# Get existing pipelines and triggers
$global:getpl = Get-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$global:gettr = Get-AzDataFactoryV2Trigger -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$plarray = @()
$trarray = @()
ForEach ($p in $getpl.Name) {
	$plarray += $p
}
ForEach ($p in $gettr.Name) {
	$trarray += $p
}

#
### FUNCTIONS ###
#

function Create-Triggers-FromPipeline {

Param ([array]$row)
# v.1.0 initial, v.1.1 lilmited to file json (based on Create-DatasetJson)

# Create corresponding triggers	
	$trg_dataset = $pipelines | Where-Object {$_.PipelineName -eq "$($row.pipelinename)"}
	$trg_blobpath = "/$($trg_dataset.containername)/blobs/$name"
	$trg_name = "trg_$name"
	$json_tr = $(Join-Path $path_triggers "$trg_name.json") #?

	$tr_template = "$t_datafile"
	$tr_template = $tr_template -replace "                 ", "`n"
	$tr_template = $tr_template -replace "          ", "`n"
	$tr_template = $tr_template -replace "		", "`n"
	$tr_template = $tr_template -replace "<triggername>", "$trg_name"
	$tr_template = $tr_template -replace "<pipelinename>", "$name"
	$tr_template = $tr_template -replace "<blobPathBeginsWith>", "$trg_blobpath"
	$tr_template = $tr_template -replace "<tenantid>", "$subscriptionid"
	$tr_template = $tr_template -replace "<resourcegroup>", "$resourcegroupname"
	$tr_template = $tr_template -replace "<storagename>", "$storagename"
	$tr_template > $json_tr

	if($trarray -eq $name) {
		Write-Host "Trigger: $trg_name --> NOK already exists" -ForegroundColor Red
	} else {
		Write-Host "Trigger: $trg_name --> OK new trigger created" 

		$newTrigger = New-AzDataFactoryV2Trigger -ResourceGroupName $resourcegroupname `
		-DataFactoryName $datafactoryname -Name $trg_name -Force `
		-File $json_tr
		
		<## v0
		$startTrigger = Start-AzDataFactoryV2Trigger -ResourceGroupName $resourcegroupname `
		-DataFactoryName $datafactoryname -TriggerName $trg_name -Force
		##>
	} 
	
}	

$joinedObject = Foreach ($row in $pipelines) 
{
	$name = "$($row.pipelinename)"
	$t = Create-Triggers-FromPipeline $row
}



