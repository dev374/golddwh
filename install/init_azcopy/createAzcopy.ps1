$azloc = (curl https://aka.ms/downloadazcopy-v10-windows -MaximumRedirection 0 -ErrorAction silentlycontinue).headers.location
$temploc = "C:\temp"
$etlloc = $main + "\..\etl"
$azdest = $temploc + "\azcopy.zip"

wget $azloc -outfile $azdest
expand-archive -path $azdest -DestinationPath $temploc
cd $temploc
$p = $(Get-ChildItem -Filter "*azcopy*windows*").Name
cd $p
cp ./azcopy.exe $etlloc
cd $etlloc
Get-ChildItem -Filter "*azcopy*"

<#

# Clean up
rm $azdest
rmdir $($temploc + "\" + $p) 

#>


