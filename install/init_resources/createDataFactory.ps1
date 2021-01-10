# Create Data Factory

$edf = Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName
if($edf.DatafactoryName -like $datafactoryname) {
		echo "OK. Datafactoryname $datafactoryname exists"

} else {
	# Create DF
	echo "OK. Creating a new DF..."
	$df = New-AzDataFactoryV2 -ResourceGroupName $resourceGroupName `
		-Name $datafactoryname `
		-Location $location
		
	If ($df) {
		write-host "OK. New Data Factory is called $df.DatafactoryName"
	}
}

