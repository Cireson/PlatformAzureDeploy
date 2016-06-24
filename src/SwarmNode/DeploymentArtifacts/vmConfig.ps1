#
# Installs and configures Cireson Platform on the current vm
#

param
(
    [string]$HostName = $(throw "HostName is required."),
    [string]$sqlServer = $(throw "sqlServer is required."),
    [string]$dbName = $(throw "dbName is required."),
    [string]$sqlUserName = $(throw "sqlUserName is required."),
    [string]$sqlPassword = $(throw "sqlPassword is required."),
    [string]$platformVersion = $(throw "platformVersion is required."),
	[string]$platformRole = "Web"
)

.\ConfigureWinRM.ps1 $HostName

.\PlatformDownload.ps1 -path 'c:\Cireson.Platform.Host' -sqlServer $sqlServer -dbName $dbName -sqlUserName $sqlUserName -sqlPassword $sqlPassword -version $platformVersion

.\FixTP5NtwkBug.ps1 

.\AddAccountToLogonAsService $sqlUserName

#todo: need a way to specify an ssl cert from storage, install it locally, and set it up with the service.
$localUserName = '.\' + $sqlUserName
$args = "-i", "-sn", "CiresonPlatform", "-sdn", "CiresonPlatform", "-usr", $localUserName, "-pwd", $sqlPassword

if($platformRole -eq "Worker"){
	$args.Add("-worker")
	$args.Add("-noweb")
}

if($platformRole -eq "Both"){
	$args.Add("-worker")
}

#install platform service locally, and start it running
start-process "C:\Cireson.Platform.Host\Cireson.Platform.Host.exe" -ArgumentList $args | Out-File "C:\Cireson.Platform.Host\Cireson.Platform.Host.InstallLog.txt"

#todo: need to add ssl support.
#https://azure.microsoft.com/en-us/documentation/articles/app-service-web-arm-with-msdeploy-provision/