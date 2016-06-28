# Azure Cireson

This Microsoft Azure template creates 
* An Azure PaaS database
* Docker host on Windows 2016 TP5
* Folder c:\cireson.platform.host containing the Cireson Platform
* Docker container bound to port 80, with above folder mounted and platform started

Platform will then be accessible at http://hostname.azureregion.cloudapp.azure.com/api 

<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FCireson%2FPlatformAzureDeploy%2Fmaster%2Fsrc%2fSwarmNode%2fTemplates%2fazuredeploy.json"><img src="http://azuredeploy.net/deploybutton.png"/></a>

Click the "Deploy to Azure" button and edit the parameter values as necessary.

NOTE: There is a network bug in Windows 2016 TP5 that may impact container connectivity. Fix from MS is coming soon, but the workaround is incorporated into this deployment. If needed, workaround at https://msdn.microsoft.com/en-us/virtualization/windowscontainers/management/container_networking. 

<hr />
This Microsoft Azure template creates 
* An Azure PaaS database
* Windows 2016 TP5 VM
* Folder c:\cireson.platform.host containing the Cireson Platform
* Installs the platform host locally as a service.

Platform will then be accessible at http://hostname.azureregion.cloudapp.azure.com/api 

<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FCireson%2FPlatformAzureDeploy%2Fmaster%2Fsrc%2fSwarmNode%2fTemplates%2fazureVmDeploy.json"><img src="http://azuredeploy.net/deploybutton.png"/></a>

Click the "Deploy to Azure" button and edit the parameter values as necessary.

<hr />

This Microsoft Azure template creates 
* A Service Bus Namespace
* Windows 2016 TP5 VM
* Folder c:\cireson.platform.host containing the Cireson Platform
* Installs the platform host locally as a service.

Platform will then be accessible at http://hostname.azureregion.cloudapp.azure.com/api 

<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FCireson%2FPlatformAzureDeploy%2Fmaster%2Fsrc%2fSwarmNode%2fTemplates%2fServiceBusDeploy.json"><img src="http://azuredeploy.net/deploybutton.png"/></a>

Click the "Deploy to Azure" button and edit the parameter values as necessary.
