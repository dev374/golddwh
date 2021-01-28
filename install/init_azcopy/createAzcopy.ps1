# Create AzCopy

Write-Host "`n--> Creating (DEV) AzCopy" -ForegroundColor Green

$etlloc = $(Join-Path $main $c.path.etl)
$azdest = $temploc + "\azcopy.zip"

if (-not(Test-Path($(Join-Path $etlloc "azcopy.exe")))) {
    Write-Host "`n Downloading AzCopy" -ForegroundColor Cyan
    $azloc = (curl https://aka.ms/downloadazcopy-v10-windows -MaximumRedirection 0 -ErrorAction silentlycontinue).headers.location
	wget $azloc -outfile $azdest
	expand-archive -path $azdest -DestinationPath $temploc -Force

	cd $temploc
	$p = $(Get-ChildItem -Filter "azcopy*windows*").Name | Sort-Object -Property LastWriteTime -Desc | Select -First 1
	
	cd $(Join-Path $temploc $p)
	cp ./azcopy.exe $etlloc -force
	cd $etlloc
	Get-ChildItem -Filter "*azcopy*"

	# Clean up
	rm $azdest -Recurse
	if (Test-Path( $($temploc + "\" + $p) )) {
		rmdir $($temploc + "\" + $p) -Force
	}
} else {
	Write-Host "`n The file $(Join-Path $etlloc "azcopy.exe") already exists. Continue." -ForegroundColor Cyan
}
<#
#>


