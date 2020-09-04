
########################
# Variables
########################
cls
& c:\Dev\golddwh\install\config\initGlobalConfig.ps1
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

        $content = Get-Content $Newfiletemp
        $content = $content -replace ',', ';'
        $content > $Newfile 
        sleep 1
        Remove-Item $Newfiletemp 
	}
	$Excel.Quit()
}

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
$imparray = Get-ChildItem $importpath -File

ForEach ($i in $imparray.Name) {
	if($i -like "*.xlsx") {
        ExcelToCsv -File $i
    }

	if ($piparray.ContainsKey($i)) {
		if($i -like 'dat*') { $flagloaddata = 1 }
		if($i -like 'met*') { $flagmetadata = 1 }
	}

}

# Copy when file has its pipeline, else message 'Pipeline for the file or import files not found'
	if($flagloaddata -eq 1) {
 		Write-Host "`n--> Copying data to the container: metadata ($blobendpointmetadata)" -ForegroundColor Blue
       .\azcopy copy $(Join-Path $importpath "dat*.csv") $($blobendpointloaddata + $saskey) --recursive=true
    }
	if($flagmetadata -eq 1) {
 		Write-Host "`n--> Copying data to the container: loaddata ($blobendpointmetadata)" -ForegroundColor Blue
       .\azcopy copy $(Join-Path $importpath "met*.csv") $($blobendpointmetadata + $saskey) --recursive=true
    }

########################
# Archive
########################
$curdate = Get-Date -Format yyyy-MM-dd_hhmm
$newfolder = New-Item -Path $(Join-Path $importpath "..\archive\$curdate") -ItemType Directory
Write-Host "`n--> Archiving data in th folder: $newfolder " -ForegroundColor Green
Move-Item $(Join-Path $importpath *.*) $newfolder
sleep 1