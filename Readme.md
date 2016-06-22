# Azure Cireson

This Microsoft Azure template creates 
* An Azure PaaS database
* Docker host on Windows 2016 TP5
* Folder c:\cireson.platform.host containing the Cireson Platform
* Docker container bound to port 80, with above folder mounted and platform started

Platform will then be accessible at http://hostname.azureregion.cloudapp.azure.com/api 

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpzerger%2FCiresonDocker%2Fmaster%2Fazuredeploy.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>

Click the "Deploy to Azure" button and edit the parameter values as necessary.

NOTE: There is a network bug in Windows 2016 TP5 that may impact container connectivity. Fix from MS is coming soon, but the workaround is incorporated into this deployment. If needed, workaround at https://msdn.microsoft.com/en-us/virtualization/windowscontainers/management/container_networking. 





