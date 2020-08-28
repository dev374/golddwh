
# Create a resource group
$rgn = Get-AzResourceGroup
$rgnarray = @()
ForEach ($r in $rgn.resourcegroupname) {
	$rgnarray += $r
}
if($rgnarray -like $resourceGroupName) {
	echo "The resourcegroup: $resourceGroupName already exists"
} else {
	echo "OK new resourcegroup is $resourceGroupName" 

    # Create resourcegroupname
	$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
}
