# This should run from any location
# Global config load within a file or separately:returns variable $c to use in every script
$global:c = Get-Content $(Join-Path $pwd "config\config.json") | ConvertFrom-Json

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
$global:databaseName = $c.server.databaseName
$global:datafactoryname = $c.datafactory.datafactoryname
$global:linkedserviceblob = $c.datafactory.linkedserviceblob
$global:linkedservicesql = $c.datafactory.linkedservicesql
$global:linkedservicejsonext = $c.datafactory.linkedservicejsonext
$global:storagename = $c.storage.storagename
$global:loginstallfile = $c.path.loginstallfile
$global:temploc = $c.general.temploc
$global:main = $(pwd).Path
<# For future use
$global: = $c.
#>


# Connect-AzAccount
if($connectazaccount -eq 1) {
	Connect-AzAccount
	Select-AzSubscription -Subscription $subscriptionname #"Visual Studio Professional Subscription"
}

