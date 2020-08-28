cls

cd "c:\Dev\golddwh\install\"

Write-Host "`n--> Loading configuration" -ForegroundColor Green
& .\config\initGlobalConfig.ps1

# Run 'Dummy check' through install - pwd is where install folder (hello) is
& $($main + "\init_azcopy\dummycheck.ps1")
cd $main

Write-Host "`n--> Creating (DEV) resources" -ForegroundColor Green


& .\init_resources\createResourceGroup.ps1
<#
& .\init_resources\createStorage.ps1

& .\init_resources\createServer.ps1

& .\init_resources\createDatabase.ps1

& .\init_azcopy\createAzcopy.ps1


Write-Host "`n--> Creating (DEV) Datafactory" -ForegroundColor Green
& .\init_resources\createDataFactory.ps1

& .\init_datafactory\createLinkedServices.ps1

& .\init_datafactory\createDatasets.ps1

& .\init_datafactory\createPipelines.ps1
#>
& .\init_datafactory\createTriggers.ps1
<##>

sleep 1
