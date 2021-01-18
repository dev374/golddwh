
########################
# Variables
########################    cd C:\dev\golddwh\etl
cls
cd $(Join-Path $pwd "..\install")
& .\config\initGlobalConfig.ps1

cd $etlpath
Write-Host "`n--> Loading data to the cloud storage: $blobendpointmetadata" -ForegroundColor Green

# Function
Function ExcelToCsv ($File) {
	if($File -like "*.xlsx") {
		$myDir = $importpath
		$ExcelFile = "$myDir\" + $File
		$Newfilename = $File -replace ".xlsx", ".csv"
        $Newfile = $(Join-Path $myDir $Newfilename)
        $Newfiletemp = $(Join-Path $myDir "tmp_$Newfilename")
		$Excel = New-Object -ComObject Excel.Application
		$Excel.displayalerts = $false
		$wb = $Excel.Workbooks.Open($excelFile)
		
		ForEach ($ws in $wb.Worksheets) {
            Write-Host " * Converting to csv file: $Newfiletemp *" -ForegroundColor Magenta
			$ws.SaveAs($Newfiletemp, 6)
		}
		$Excel.displayalerts = $true
		$Excel.Quit()

        # UTF8 encoding + ;
        $content = Get-Content -Raw $Newfiletemp
        $Newfile = New-Object System.Text.UTF8Encoding $True
        $content = $content -replace ',', ';'
        $content > $Newfile 
        sleep 1
        Remove-Item $Newfiletemp 
	}
	$Excel.Quit()
}
Function StorageKey () {
    $global:storagekeynr = $c.storage.storagekeynr
    $storagekeyfile = $(Join-Path $c.path.config "storagekey.txt")
    if (-not(Test-Path($storagekeyfile))) {

	    echo "OK generating new storage key " 
	    $keyarray = New-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storagename -KeyName $storagekeynr
	    $newkey = $($keyarray.Keys | Where-Object {$_.KeyName -eq $storagekeynr}).Value
	    $newkey > $storagekeyfile

    } else {	
	    Write-Host "Storage key for $storagename exists"
	
	    $keyarray = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storagename 
	    $global:newkey = $($keyarray | Where-Object {$_.KeyName -eq $storagekeynr}).Value
	
	    $savedkey = Get-Content $storagekeyfile
	    if ($savedkey -ne $newkey) {
		    $newkey > $storagekeyfile
	    }
    }
}

Function Convert-CsvInBatch
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true)][String]$Folder
	)
	$ErrorActionPreference = 'Stop'
    $ExcelFiles = Get-ChildItem -Path $Folder -Filter *.xlsx -Recurse

	$excelApp = New-Object -ComObject Excel.Application
	$excelApp.DisplayAlerts = $false

	$ExcelFiles | ForEach-Object {
		$workbook = $excelApp.Workbooks.Open($_.FullName)
		$csvFilePath = $_.FullName -replace "\.xlsx$", ".csv"
		$workbook.SaveAs($csvFilePath, [Microsoft.Office.Interop.Excel.XlFileFormat]::xlCSV)
		$workbook.Close()
	}

	# Release Excel Com Object resource
	$excelApp.Workbooks.Close()
	$excelApp.Visible = $true
	Start-Sleep 1
	$excelApp.Quit()
	[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelApp) | Out-Null
}

########################
# Storage key
########################
StorageKey
$context = New-AzStorageContext -StorageAccountName $storagename -StorageAccountKey $newkey
# Create containers if doesn't exist
$ec = Get-AzStorageContainer -Context $context
$containers.split() | ForEach {
	if($ec.Name -like $_) {
		echo "OK. Container $_ exists"
	} else {
		$_ | New-AzStorageContainer -Permission Container -Context $context  # create new container
	}	
}

# Generate SAS tokens
$sasm = New-AzStorageAccountSASToken -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission "racwdlup" -Context $context
$saskeyfile = $(Join-Path $c.path.config "sas_token.txt")
$sasm > $saskeyfile
$saskey = Get-Content $(Join-Path $c.path.config "sas_token.txt")

########################
# Copy with AzCopy
########################
# Check existing pipelines
$getpl = Get-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryname
$piparray = @{}
ForEach ($p in $getpl) {
	if($($p.Parameters.filename.DefaultValue) -ne $null) {
		$piparray += @{ $($p.Parameters.filename.DefaultValue) = @{Container = $($p.Parameters.importcontainer.DefaultValue);Pipelinename = $($p.Name)}}
	}
}

$flagloaddata = 0
$flagmetadata = 0
$flagdatamodel = 0
$imparray = Get-ChildItem $importpath -File

ForEach ($i in $imparray.Name) {
	if($i -like "*.xlsx") {
        Convert-CsvInBatch $importpath
   		$i = $i -replace ".xlsx", ".csv"
    }

	if ($piparray.ContainsKey($i)) { 
		if($i -like 'met*') { $flagmetadata = 1 }
		if($i -like 'data_model*') { $flagdatamodel = 1 }
		else { $flagloaddata = 1 }
	}
$i 
$flagdatamodel
$flagloaddata
} 

# Copy when file has its pipeline, else message 'Pipeline for the file or import files not found'
 	if($flagmetadata -eq 1) {
        Write-Host "`n--> Copying data to the container: metadata ($blobendpointmetadata)" -ForegroundColor Blue
       .\azcopy copy $(Join-Path $importpath "met*.csv") $($blobendpointmetadata + $saskey) --recursive=true
    }
	if($flagloaddata -eq 1) {
        Write-Host "`n--> Copying data to the container: loaddata ($blobendpointloaddata)" -ForegroundColor Blue
       .\azcopy copy $(Join-Path $importpath "dat*.csv") $($blobendpointloaddata + $saskey) --recursive=true
    }
 	if($flagdatamodel -eq 1) {
        Write-Host "`n--> Copying data to the container: metadata ($blobendpointmetadata)" -ForegroundColor Blue
       .\azcopy copy $(Join-Path $importpath "data_model*.csv") $($blobendpointmetadata + $saskey) --recursive=true
    }

########################
# Archive
########################
$curdate = Get-Date -Format yyyy-MM-dd_hhmmss
$newfolder = New-Item -Path $(Join-Path $importpath "..\archive\$curdate") -ItemType Directory
Write-Host "`n--> Archiving data in th folder: $newfolder " -ForegroundColor Green
Move-Item $(Join-Path $importpath *.*) $newfolder
sleep 1
