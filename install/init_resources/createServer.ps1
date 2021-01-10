
# Create a server with a system wide unique server name
$srv = Get-AzSqlServer
$srvarray  = @()
ForEach ($s in $srv.servername) {
    $srvarray += $s
}
if ($srvarray -like $serverName) {
	echo "The $serverName already exists"
} else {
	echo "OK creating SQL Server called $serverName" 

    # Create server
    $server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
        -ServerName $serverName `
        -Location $location `
        -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminLogin, $(ConvertTo-SecureString -String $adminPass -AsPlainText -Force))

    # Create a server firewall rule that allows access from the specified IP range
    $serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
        -ServerName $serverName `
        -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp

    $serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
        -ServerName $serverName `
		-AllowAllAzureIPs
}
