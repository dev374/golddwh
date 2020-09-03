cls
Write-Host "`n--> Loading data to the container: loaddata ($blobendpointloaddata)" -ForegroundColor Green

########################
# Variables
########################
& c:\Dev\golddwh\install\config\initGlobalConfig.ps1

cd $etlpath

########################
# Copy with AzCopy
########################
$status = .\azcopy copy $importpath $($blobendpointloaddata + $saskey) --recursive=true

########################
# Archive
########################
$curdate = Get-Date -Format yyyy-MM-dd_hhmm
$newfolder = New-Item -Path $(Join-Path $importpath "\archive\$curdate") -ItemType Directory
$newfolder
Move-Item $(Join-Path $importpath *.*) $newfolder