# Create storage
Write-Host "`n--> Creating (DEV) storage account" -ForegroundColor Green

$global:storagekeynr = $c.storage.storagekeynr

$sto = Get-AzStorageAccount
$stoarray = @()
ForEach ($s in $sto.StorageAccountName) {
	$stoarray += $s
}

if($stoarray -like $storagename) {
	echo "The storage account: $storagename already exists"
} else {
	echo "OK new storage account is $storagename" 

    # Create 
	$storage = New-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storagename -Location $location -SkuName Standard_LRS -Kind StorageV2 -AssignIdentity
}
	
$storagekeyfile = $(Join-Path $c.path.config "storagekey.txt")
if (-not(Test-Path($storagekeyfile))) {

	echo "OK generating new storage key " 
	$keyarray = New-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storagename -KeyName $storagekeynr
	$newkey = $($keyarray.Keys | Where-Object {$_.KeyName -eq $storagekeynr}).Value
	$newkey > $storagekeyfile

} else {	
	Write-Host "Storage key for $storagename exists"
	
	$keyarray = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storagename 
	$newkey = $($keyarray | Where-Object {$_.KeyName -eq $storagekeynr}).Value
	
	$savedkey = Get-Content $storagekeyfile
	if ($savedkey -ne $newkey) {
		$newkey > $storagekeyfile
	}
}

$context = New-AzStorageContext -StorageAccountName $storagename -StorageAccountKey $newkey
sleep 1

# Create containers if doesn't exist
$ec = Get-AzStorageContainer -Context $context
$containers.split() | ForEach {
	if($ec.Name -like $_) {
		echo "OK. Container $_ exists"
	} else {
		$_ | New-AzStorageContainer -Permission Container -Context $context  # create new container
	}
}

## old way ## $containers.split() | New-AzStorageContainer -Permission Container -Context $context

