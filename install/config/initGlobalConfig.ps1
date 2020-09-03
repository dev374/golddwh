# This should run from any location
# Global config load within a file or separately:returns variable $c to use in every script
$global:main = "C:\Dev\golddwh\install"
$global:c = Get-Content $(Join-Path $main "config\config.json") | ConvertFrom-Json

if(!$c) { 
	echo 'Empty config. Load config first'
	pwd
	exit
} else {
    echo "Config loaded"
}

# Global variables - they are that many scripts may use
$global:connectAzAccount = $c.general.connectazaccount
$global:subscriptionName = $c.general.subscriptionname
$global:resourceGroupName = $c.server.resourcegroupname
$global:location = $c.server.location
$global:serverName = $c.server.servername
$global:databaseName = $c.database.databaseName
$global:objective = $c.database.objective
$global:path_config = $c.path.config
$global:importpath = $c.path.import
$global:etlpath = $c.path.etl

$global:startIp = $c.server.startIp
$global:endIp = $c.server.endip
$global:adminLogin = $c.database.adminLogin
$global:adminPass = $c.database.adminPass

$global:datafactoryname = $c.datafactory.datafactoryname
$global:linkedserviceblob = $c.datafactory.linkedserviceblob
$global:linkedservicesql = $c.datafactory.linkedservicesql
$global:linkedservicejsonext = $c.datafactory.linkedservicejsonext
$global:storagename = $c.storage.storagename
$global:storagekeyfilename = $c.storage.storagekeyfilename
$global:containers = $c.storage.containers
$global:storagekey = Get-Content -Path $(Join-Path $path_config $storagekeyfilename) -Encoding utf8
$global:saskey = $c.storage.saskey
$global:blobendpointmetadata = $c.storage.blobendpointmetadata
$global:blobendpointloaddata = $c.storage.blobendpointloaddata

$global:loginstallfile = $c.path.loginstallfile
$global:temploc = $c.general.temploc

<# For future use
$global: = $c.
#>

# Connect-AzAccount
if($connectazaccount -eq 1) {
	Connect-AzAccount
	Select-AzSubscription -Subscription $subscriptionname
}

$s = Get-AzSubscription
$global:subscriptionid = $s.Id
$global:tenantid = $s.TenantId