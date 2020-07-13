
$global:location = $c.server.location
$global:serverName = $c.server.servername
$global:databaseName = $c.server.databaseName
$global:startIp = $c.server.startIp
$global:endIp = $c.server.endip

$global:adminLogin = $c.database.adminLogin
$global:adminPass = $c.database.adminPass
$global:databaseName = $c.database.databaseName

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
