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
	[string]$platformRole = "Web",
	[string]$serviceBusConnectionString = ""
)
$installRoot = "C:\Cireson.Platform.Host"

.\ConfigureWinRM.ps1 $HostName

.\PlatformDownload.ps1 -path 'c:\Cireson.Platform.Host' -sqlServer $sqlServer -dbName $dbName -sqlUserName $sqlUserName -sqlPassword $sqlPassword -version $platformVersion

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

#set the connection string for the servicebus
[xml]$config = Get-Content  "$installRoot\Cireson.Platform.Host.exe.config"
$sbConnectionString = $config.CreateElement("add")
$sbConnectionString.SetAttribute("key","ServiceBusConnectionString")
$sbConnectionString.SetAttribute("value",$serviceBusConnectionString)
$config.configuration.appSettings.AppendChild($sbConnectionString)
$config.Save("C:\Cireson.Platform.Host\Cireson.Platform.Host.exe.config")

new-item "$installRoot\cpex" -ItemType Directory

#create cpexinstall json
#***Add additional cpex nuget references as needed.
$cpexJson = @"
[
{
	"Name":"Cireson.Platform.Extension.WebUi",
	"Version":"0.1.0-rc0123"
},
{
	"Name":"Cireson.AssetManagement.Core",
	"Version":"0.1.0-rc0008"
},
{
    "Name": "Extension.AzureServiceBus",
    "Version": "0.1.0-rc0001"
}
]
"@
Set-Content "$installRoot\cpex\armInstall.json" -Value $cpexJson

#install platform service locally, and start it running
start-process "C:\Cireson.Platform.Host\Cireson.Platform.Host.exe" -ArgumentList $args | Out-File "$installRoot\Cireson.Platform.Host.InstallLog.txt"

#open port 80 and 443
netsh advfirewall firewall add rule name="Http 80" dir=in action=allow protocol=TCP localport=80
netsh advfirewall firewall add rule name="Https 443" dir=in action=allow protocol=TCP localport=443
#todo: need to add ssl support.
#https://azure.microsoft.com/en-us/documentation/articles/app-service-web-arm-with-msdeploy-provision/

