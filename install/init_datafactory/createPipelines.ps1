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

$path_pipelines 	= $c.path.pipelines
$path_templates 	= $c.path.adftemplatespl
$path_config 		= $c.path.config

$global:activities  = Get-Content $(Join-Path $path_config $pl_act_config) | ConvertFrom-Json
$global:pipelines 	= Get-Content -Path $(Join-Path $path_config $pl_config) | ConvertFrom-Csv -Delimiter ';'
$p_archive 			= Get-Content -Path $(Join-Path $path_templates $pl_act_archive) 
$p_copydata			= Get-Content -Path $(Join-Path $path_templates $pl_act_copydata) 
$p_logstart 		= Get-Content -Path $(Join-Path $path_templates $pl_act_log_start) 
$p_logfinish 		= Get-Content -Path $(Join-Path $path_templates $pl_act_log_finish) 
$p_logerror 		= Get-Content -Path $(Join-Path $path_templates $pl_act_log_error) 
$pl_start			= Get-Content -Path $(Join-Path $path_templates $pl_tem_start) 
$pl_ending			= Get-Content -Path $(Join-Path $path_templates $pl_tem_ending) 


# Get existing datasets
$getpl = Get-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$plarray = @()
ForEach ($p in $getpl.Name) {
	$plarray += $p
}


# Create templates for each
$joinedObject = Foreach ($row in $pipelines) 
{
	if ($row.typeid -eq 1) { 
		$name = "$($row.pipelinename)"     #   , $p_logerror 
		
		$pl_template = "$pl_start $p_logstart , $p_copydata , $p_archive , $p_logfinish $pl_ending"	
			
		# Prepare tamplate in templates		
		$pl_template = $pl_template -replace "<filename>", "$($row.filename)"
		$pl_template = $pl_template -replace "<pipelinename>", "$name"
		$pl_template = $pl_template -replace "<sourcemetadatablob>", "$($activities.blobs.sourcemetadatablob)"
		$pl_template = $pl_template -replace "<sourceloaddatablob>", "$($activities.blobs.sourceloaddatablob)"
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
	Write-Host "START pipelinename $name" 

	
	# Create 
	if($dsarray -eq $name) {
		Write-Host "SKIP pipeline: $name already exists"
	} else {
		Write-Host "OK new pipeline created: $name" 

		$newDataset = New-AzDataFactoryV2Pipeline -ResourceGroupName $resourcegroupname `
		-DataFactoryName $datafactoryname -Name $name `
		-File $json
	} 

	
}

