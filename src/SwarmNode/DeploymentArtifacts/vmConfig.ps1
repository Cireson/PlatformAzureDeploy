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
    [string]$platformVersion = $(throw "platformVersion is required.")
)

.\ConfigureWinRM.ps1 $HostName

.\PlatformDownload.ps1 -path 'c:\Cireson.Platform.Host' -sqlServer $sqlServer -dbName $dbName -sqlUserName $sqlUserName -sqlPassword $sqlPassword -version $platformVersion

.\FixTP5NtwkBug.ps1 

.\AddAccountToLogonAsService $sqlUserName

#todo: need a way to specify an ssl cert from storage, install it locally, and set it up with the service.

#install platform service locally, and start it running
start-process "C:\Cireson.Platform.Host\Cireson.Platform.Host.exe" -ArgumentList "-i -sn CiresonPlatform -sdn CiresonPlatform -usr $sqlUserName -pwd $sqlPassword" 

