cls

# Run 'Dummy check' through install - pwd is ehere install is
$global:main = $(pwd).Path
& $($main + "\init_azcopy\dummycheck.ps1")
cd $main

echo 'Config load'

echo '`nCreating Azure Resources'
& .\init_resources\createResourceGroup.ps1
<#
& .\init_resources\createServer.ps1
& .\init_resources\createDatabase.ps1
#>
& .\init_resources\createDataFactory.ps1

echo '`nCreating AzCopy Resource'
& .\init_azcopy\createAzcopy.ps1

sleep 3