# Config load
$c = Get-Content .\config.json | ConvertFrom-Json

if(!$c) {
	echo 'Empty config. Load config first'
	exit
}

# Variables - set the resource group name, location, servername, database and allowed IP range
$global:storagename = $c.storage.storageaccountname
$global:storagekey = $c.storage.storageaccountkey
$adflinkedservices = $c.path.adflinkedservices
$adflinkedservicesblobfile = $c.path.adflinkedservicesblobfile

# Generate
$ls_template = '
{
    "name": "conn_linkedservice",
    "properties": {
        "annotations": [],
        "type": "AzureBlobStorage",
        "typeProperties": {
            "connectionString": "DefaultEndpointsProtocol=https;AccountName=<accountName>;AccountKey=<accountKey>;EndpointSuffix=core.windows.net"
        }
    }
}' 

$ls_template += $ls_template -replace "<accountName>", $storagename
$ls_template += $ls_template -replace "<accountKey>", $storagekey

$file = Join-Path $adflinkedservices $adflinkedservicesblobfile

Move-Item $file $(Get-Date)$file
$ls_template >> $file

# Create linked services
