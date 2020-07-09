# Initial
#	Uninstall-AzureRm
#	Install-Module -Name Az -AllowClobber -Scope AllUsers

# Config load
$c = Get-Content .\config.json | ConvertFrom-Json

if(!$c) { 
	echo 'Empty config. Load config first'
	exit
}

# Connect-AzAccount
Connect-AzAccount
Select-AzSubscription -Subscription "Visual Studio Professional Subscription"

# Variables - set the resource group name, location, servername, database and allowed IP range
$global:resourceGroupName = $c.server.resourcegroupname
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
