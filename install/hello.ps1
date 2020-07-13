cls

Write-Host "`n--> Config load" -ForegroundColor Green
& .\init_resources\initGlobalConfig.ps1

# Run 'Dummy check' through install - pwd is where install folder (hello) is
$global:main = $(pwd).Path
& $($main + "\init_azcopy\dummycheck.ps1")
cd $main

Write-Host "`n--> Creating Azure resources" -ForegroundColor Green
& .\init_resources\createResourceGroup.ps1

& .\init_resources\createServer.ps1

& .\init_resources\createDatabase.ps1


Write-Host "`n--> Creating Data factory resource" -ForegroundColor Green

& .\init_resources\createDataFactory.ps1

& .\init_datafactory\createLinkedServices.ps1

Write-Host "`n--> Creating AzCopy" -ForegroundColor Green
& .\init_azcopy\createAzcopy.ps1

sleep 3