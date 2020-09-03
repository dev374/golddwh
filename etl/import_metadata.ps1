cls
Write-Host "`n--> Loading data to the container: metadata ($blobendpointmetadata)" -ForegroundColor Green

########################
# Variables
########################
#& c:\Dev\golddwh\install\config\initGlobalConfig.ps1

cd $etlpath

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
            echo " * $Newfiletemp *"
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


$imparray = Get-ChildItem $importpath -File

ForEach ($i in $imparray.Name) {
	if($i -like "*.xlsx") {
        ExcelToCsv -File $i
    }
	if ($piparray.ContainsKey($i)) {
		echo 1
	}

}

# Copy when file has its pipeline, else message 'Pipeline for the file ot found'
.\azcopy copy $(Join-Path $importpath "*.csv") $($blobendpointmetadata + $saskey) --recursive=true

########################
# Archive
########################
$curdate = Get-Date -Format yyyy-MM-dd_hhmm
$newfolder = New-Item -Path $(Join-Path $importpath "..\archive\$curdate") -ItemType Directory
$newfolder
Move-Item $(Join-Path $importpath *.*) $newfolder