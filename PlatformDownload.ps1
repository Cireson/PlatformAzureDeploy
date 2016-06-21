#Function PrepPlatformContainerFolder{

Param(
[string]$path = 'c:\Cireson.Platform.Host',
[string]$sqlServer = "vmexsqlsvri3s3ayqm2nipe",
[string]$dbName = "CiresonPlatform",
[string]$sqlUserName = "sqladmin",
[string]$sqlPassword = "P@ssw0rd1!",
[string]$version = "1.0.68-rc0008"
)

if(Test-Path $path){
    Remove-Item $path -recurse
}

New-Item $path -ItemType Directory
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Cireson.Platform.Core.Host/$version -OutFile $path\$version.nupkg

[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
[System.IO.Compression.ZipFile]::ExtractToDirectory("$path\$version.nupkg", "$path\$version") 
[System.IO.Compression.ZipFile]::ExtractToDirectory("$path\$version\content\PlatformRuntime\Cireson.Platform.Host.zip", "$path") 


Remove-Item $path\$version.nupkg -force
Remove-Item $path\$version -recurse -Force

$connectionString = "Server=tcp:$sqlServer.database.windows.net,1433;Data Source=$sqlServer.database.windows.net;Initial Catalog=$dbName;Persist Security Info=False;User ID=$sqlUserName;Password=$sqlPassword;Encrypt=True;Connection Timeout=30;"

$configPath = "$path\Cireson.Platform.Host.exe.config"

[xml]$configFile = Get-Content $configPath

$cstring = (($configFile.configuration.connectionStrings).add | where {$_.name -eq "CiresonDatabase"})
$cstring.connectionString = $connectionString
$configFile.Save($configPath) 

#}