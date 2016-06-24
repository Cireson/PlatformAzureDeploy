# Configure freshly-provisioned TP5 instance for needs specific to the application
#
# Derived from https://github.com/StefanScherer/docker-windows-azure/blob/master/containerConfig.ps1
#
#  Arguments : HostName, specifies the FQDN of machine or domain

param
(
    [string] $HostName = $(throw "HostName is required."),
    [string]$sqlServer = $(throw "sqlServer is required."),
    [string]$dbName = $(throw "dbName is required."),
    [string]$sqlUserName = $(throw "sqlUserName is required."),
    [string]$sqlPassword = $(throw "sqlPassword is required."),
    [string]$platformVersion = $(throw "platformVersion is required.")
)

$Logfile = "C:\containerConfig.log"

function LogWrite {
   Param ([string]$logstring)
   $now = Get-Date -format s
   Add-Content $Logfile -value "$now $logstring"
   Write-Host $logstring
}

LogWrite "containerConfig.ps1"
LogWrite "HostName = $($HostName)"
LogWrite "USERPROFILE = $($env:USERPROFILE)"
LogWrite "pwd = $($pwd)"

#Set HTTP, Docker and SSH Firewall Rules:

if (!(Get-NetFirewallRule | where {$_.Name -eq "Http"})) {
    New-NetFirewallRule -Name "Http" -DisplayName "Http" -Protocol tcp -LocalPort 80 -Action Allow -Enabled True
}

if (!(Get-NetFirewallRule | where {$_.Name -eq "Docker"})) {
    New-NetFirewallRule -Name "Docker" -DisplayName "Docker" -Protocol tcp -LocalPort 2375 -Action Allow -Enabled True
}

if (!(Get-NetFirewallRule | where {$_.Name -eq "SSH"})) {
    New-NetFirewallRule -Name "SSH" -DisplayName "SSH" -Protocol tcp -LocalPort 22 -Action Allow -Enabled True
}

#Install Windows Container feature before script below to skip its reboot cycle
Install-WindowsFeature containers

#Install Windows Container feature, Docker Engine, Base Images
#use hacked version of Install-ContainerHost.ps1 until it pull request accepted
#wget -uri https://aka.ms/tp5/Install-ContainerHost -OutFile c:\Install-ContainerHost.ps1
#wget https://raw.githubusercontent.com/brogersyh/Virtualization-Documentation/master/windows-server-container-tools/Install-ContainerHost/Install-ContainerHost.ps1 -OutFile c:\Install-ContainerHost.ps1
wget https://raw.githubusercontent.com/Cireson/PlatformAzureDeploy/master/src/SwarmNode/DeploymentArtifacts/Install-ContainerHost.ps1 -OutFile c:\Install-ContainerHost.ps1

#skip running the script here for now, since reboot cycle required from the containers feature added above - needs to be manually invoked via rdp
#c:\Install-ContainerHost.ps1

# Install OpenSSH
# see also https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH
wget https://github.com/PowerShell/Win32-OpenSSH/releases/download/12_22_2015/OpenSSH-Win64.zip -Out OpenSSH-Win64.zip -UseBasicParsing
Expand-Archive OpenSSH-Win64.zip "C:\Program Files" -Force
Push-Location "C:\Program Files\OpenSSH-Win64"
.\ssh-keygen.exe -A
copy "C:\Program Files\OpenSSH-Win64\x64\ssh-lsa.dll" C:\Windows\system32\
cmd /c setup-ssh-lsa.cmd
.\sshd.exe install
Start-Service sshd
Set-Service sshd -StartupType Automatic
Pop-Location

# Install Chocolatey
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

# install docker tools
choco install -y docker-machine -version 0.7.0
choco install -y docker-compose -version 1.7.0

.\ConfigureWinRM.ps1 $HostName

# Deploy the Docker daemon config file
.\daemonjson.ps1

.\PlatformDownload.ps1 -path 'c:\Cireson.Platform.Host' -sqlServer $sqlServer -dbName $dbName -sqlUserName $sqlUserName -sqlPassword $sqlPassword -version $platformVersion

.\FixTP5NtwkBug.ps1 

.\AddAccountToLogonAsService $sqlUserName

Start-Sleep 30

#todo: I think we need to actually create the container, create the admin user, install the platform host as a service in the container running under the admin user, and then run the container.

#start the platform
docker run -d -v c:/Cireson.Platform.Host:c:/Cireson.Platform.Host -p 80:80 windowsservercore:latest c:/Cireson.Platform.Host/Cireson.Platform.Host.exe

# No OpenSSH restart needed for Windows scenarios
# OpenSSH server needs a restart for ssh key based logins
#Restart-Computer
