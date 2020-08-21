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
$ds_config 			= $c.datasets.ds_config

$path_pipelines 	= $c.path.pipelines
$path_triggers 		= $c.path.triggers
$path_templates 	= $c.path.adftemplatespl
$path_templates_tr  = $c.path.adftemplatestr
$path_config 		= $c.path.config

$global:activities  = Get-Content $(Join-Path $path_config $pl_act_config) | ConvertFrom-Json
$global:pipelines 	= Get-Content -Path $(Join-Path $path_config $pl_config) | ConvertFrom-Csv -Delimiter ';'
$global:datasets 	= Get-Content -Path $(Join-Path $path_config $ds_config) | ConvertFrom-Csv -Delimiter ';'
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


# Create templates for each
$joinedObject = Foreach ($row in $pipelines) 
{
	$name = "$($row.pipelinename)"     #   , $p_logerror 
	if ($row.typeid -eq 1) { 
		
		$pl_template = "$p_start $p_logstart , $p_copydata , $p_archive , $p_logfinish $p_ending"	
			
		# Prepare tamplate in templates		
		$pl_template = $pl_template -replace "<filename>", "$($row.filename)"
		$pl_template = $pl_template -replace "<pipelinename>", "$name"
		$pl_template = $pl_template -replace "<sourcemetadatablob>", "$($activities.blobs.sourcemetadatablob)"
		$pl_template = $pl_template -replace "<sourceloaddatablob>", "$($activities.blobs.sourceloaddatablob)"
		$pl_template = $pl_template -replace "<sourceblobfoldername>", "$($activities.blobs.sourceblobfoldername)"
		$pl_template = $pl_template -replace "<copydatainputs>", "$($row.inputs)"
		$pl_template = $pl_template -replace "<copydataoutputs>", "$($row.outputs)"
		$pl_template = $pl_template -replace "<targetarchiveblob>", "$($activities.blobs.targetarchiveblob)"
		$pl_template = $pl_template -replace "<statusstart>", "$($activities.logging.statusstart)"
		$pl_template = $pl_template -replace "<statusfinish>", "$($activities.logging.statusfinish)"		
		$pl_template = $pl_template -replace "<archiveinputs>", "$($row.inputs)"
		$pl_template = $pl_template -replace "<archiveoutputs>", "$($activities.blobs.archivedatasetname)"
		$pl_template = $pl_template -replace "<loglinkedservicesql>", "$($activities.linkedservices.sqldwh)"
		$pl_template = $pl_template -replace "<logstoredprocedurename>", "$($activities.logging.logstoredprocedurename)"
		$pl_template = $pl_template -replace "<logloadinderrordpendendon>", "$name"
	}	

	# For all types
		$json = $(Join-Path $path_pipelines "$name.json")
		$pl_template = $pl_template -replace "                 ", "`n"
		$pl_template > $json
		Write-Host "START pipeline: $name" 
    $json > json2.json

		# Create pieline
		if($plarray -eq $name) {
			Write-Host "SKIP pipeline: $name already exists"
		} else {
			$newPipeline = New-AzDataFactoryV2Pipeline -ResourceGroupName $resourcegroupname `
			-DataFactoryName $datafactoryname -Name $name `
			-File $json
			
            Write-Host "OK new pipeline created: $name" 
		} 
		
	
	# Create corresponding triggers	
		$trg_dataset = $datasets | Where-Object {$_.DatasetName -eq "$($row.inputs)"}
		$trg_blobpath = "/$($trg_dataset.containername)/blobs/$name"
		$trg_name = "trg_$name"
		$json = $(Join-Path $path_triggers "$trg_name.json")
		
		Write-Host "START trigger: $trg_name" 
		$tr_template = "$t_datafile"
		$tr_template = $tr_template -replace "                 ", "`n"
		$tr_template = $tr_template -replace "          ", "`n"
		$tr_template = $tr_template -replace "		", "`n"
		$tr_template = $tr_template -replace "<name>", "$trg_name"
		$tr_template = $tr_template -replace "<pipelinename>", "$name"
		$tr_template = $tr_template -replace "<blobPathBeginsWith>", "$trg_blobpath"
		$tr_template = $tr_template -replace "<tenantid>", "$subscriptionid"
		$tr_template = $tr_template -replace "<resourcegroup>", "$resourcegroupname"
		$tr_template = $tr_template -replace "<storagename>", "$storagename"
		$tr_template > $json

		Write-Host $tr_template # "/$($trg_dataset.containername)/$($trg_dataset.filenameorfolder)/$($row.filename)"
		
		if($trarray -eq $name) {
			Write-Host "SKIP trigger: $name already exists"
		} else {
			Write-Host "OK new trigger created: $name" 

			$newTrigger = New-AzDataFactoryV2Trigger -ResourceGroupName $resourcegroupname `
			-DataFactoryName $datafactoryname -Name $trg_name `
			-File $json
			
			<#
			$startTrigger = Start-AzDataFactoryV2Trigger -ResourceGroupName $resourcegroupname `
			-DataFactoryName $datafactoryname -TriggerName $trg_name 
			#>
		} 
		

}



