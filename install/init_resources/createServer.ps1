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
#Connect-AzAccount
Select-AzSubscription -Subscription "Visual Studio Professional Subscription"


# Variables - set the resource group name, location, servername, database and allowed IP range
$resourceGroupName = $c.server.resourcegroupname
$location = $c.server.location
$serverName = $c.server.servername
$databaseName = $c.server.databaseName
$startIp = $c.server.startIp
$endIp = $c.server.endip


# Create a resource group
$rgn = Get-AzResourceGroup -Name $resourceGroupName
if($rgn) {
	echo $rgn
	echo "The $resourceGroupName already exists"
} else {
	$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
}


# tODO Create a server with a system wide unique server name
$srv = Get-AzSqlServer
if($c.server.servername in $srv) {
	echo "The $c.server.servername already exists"
} else {
	echo "OK"
}
	

<#
$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp

# Create a blank database with an B performance level
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "S0" 
#    -SampleName "AdventureWorksLT"

# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
#>