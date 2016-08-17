#---------------------------
#Platform Installer PS1
#---------------------------


param
(
    [string] $test = ""
)

$namedParameters = @{} #parameters dictionary
$adminPassword = ""
$defaultRepository = "https://packages.nuget.org/api/v2"

$deploymentTemplateUrl = "https://raw.githubusercontent.com/Cireson/PlatformAzureDeploy/master/src/SwarmNode/Templates/azureVmDeploy.json"
$serviceBusTemplateUrl = "https://raw.githubusercontent.com/Cireson/PlatformAzureDeploy/master/src/SwarmNode/Templates/azureServiceBusDeploy.json"
[string[]]$repoUrls =  $defaultRepository

Write-Host $repoUrls

function getParameterValue([string] $parameterName){
	if($namedParameters.ContainsKey($parameterName)){
		return $namedParameters[$parameterName]
	}
}

function setParameterValue($key, $value){
	$namedParameters[$key] = $value
}

function initializeNugetCore(){
    try{
        $installerPath = Join-Path $env:TEMP "\CiresonInstaller"
        if(!(Test-Path $installerPath)){
            new-item -Path $installerPath -ItemType "Directory"
            Invoke-WebRequest -Uri "http://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile "$installerPath\NuGet.exe"
        }
        [System.Reflection.Assembly]::LoadFile("$installerPath\NuGet.exe") | Out-Null;
    }catch{
        $Exception = $_.Exception
        Write-Error -Exception $Exception
    }  
} 

function getAvailableCpex(){
    initializeNugetCore |  Out-Null
    [NuGet.IServiceBasedRepository ] $repoFactory = [NuGet.PackageRepositoryFactory]::Default.CreateRepository($defaultRepository)
    [string[]]$frameworkVer =".NETFramework, Version=4.0"
    $cpexList = $repoFactory.Search("ciresoncpex", $frameworkVer, $true)
    return $cpexList
}

function getLocations(){
    #todo: identify location services, and only show locations that are compatible
    $locations = Get-AzureLocation | select -ExpandProperty Name 
    return $locations
}

function getPlatformVersions($preRelease){
    initializeNugetCore |  Out-Null
    [NuGet.IServiceBasedRepository ] $repoFactory = [NuGet.PackageRepositoryFactory]::Default.CreateRepository($defaultRepository)
    [string[]]$frameworkVer =".NETFramework, Version=4.0"
    $platformVersions = $repoFactory.FindPackagesById("Cireson.Platform.Core.Host") | Select-Object -ExpandProperty Version  | Sort-Object -Descending
    if($preRelease -ne $true){
        $platformVersions = $platformVersions | where {!($_.Contains("-"))}
    }

    return $platformVersions  | Select -First 10
}

function promptForMultiChoice($caption, $options, $required){
    $selections=New-Object System.Collections.ArrayList
    do{
        writeCurrentState
        write-host $caption
        if($required -eq $true){
            Write-Host "** You must select at lease one option."
        }
        $i=0
    
        foreach($option in $options){
            if($selections.Contains($i.ToString())){
                Write-Host "[$i*] - $option -Selected" 
            }else{
                Write-Host "[$i] - $option"
            }
            $i++
        }    
    
        Write-Host "<Enter> - Done"
    
        [int]$response = Read-Host
        if($response -ne $i){
            if($selections.Contains($response)){
                $selections.Remove($response) | Out-Null
            }else{
                $selections.Add($response) | Out-Null
            }
        }
    
    }until(($response -eq "") -and ($required -eq $false -or $selections.Count -gt 0))
    return $selections.ToArray()
}

function promptForChoice($caption, $options){
    $selections=New-Object System.Collections.ArrayList
    writeCurrentState
    write-host $caption "- (default = $($options[0]))"
    $i=0
    
    foreach($option in $options){
        Write-Host "[$i] - $option"
        $i++
    }   
        
    [int]$response = Read-Host
    if(!($response -gt 0 -and $response -lt $options.Length)){
        $response = "0"
    }
    return $response
}

function promptForText($caption, $required){
    writeCurrentState
    write-host $caption
    do{
    $response = Read-Host
    }until($response -ne "" -or $required -eq $false)
    return $response
}

function chooseSubscription(){
    writeCurrentState
	$subscriptions = Get-AzureRmSubscription

    if($subscriptions.Count -gt 1){
        $options = $subscriptions | select-object -ExpandProperty SubscriptionName
        $choice = promptForChoice "Select your desired Azure Subscription" $options
        Set-AzureSubscription  -SubscriptionId $($subscriptions[$choice].SubscriptionId) 
        Set-AzureRMContext -SubscriptionId $($subscriptions[$choice].SubscriptionId) 
        setParameterValue "Subscription" $subscriptions[$choice].SubscriptionName   
    }else{
        Set-AzureSubscription -SubscriptionId $($subscriptions[0].SubscriptionId)
        Set-AzureRmContext -SubscriptionId $($subscriptions[0].SubscriptionId)
        setParameterValue "Subscription" $subscriptions[0].SubscriptionName
    }
}

function chooseResourceGroup(){
    writeCurrentState
    $resourceGroups = Get-AzureRmResourceGroup | select -ExpandProperty ResourceGroupName
    $resourceGroupName = ""
    $rmType = promptForChoice "Would you like to install to an existing Resource Group, or create a new resource group?" @("New ($(getParameterValue 'DeploymentName'))","Existing")
    if($rmType -ne "0"){
        $choice = promptForChoice "Select and existing Resource Group." $resourceGroups
        $resourceGroupName = $resourceGroups[$choice]
    }else{
        $resourceGroupName = getParameterValue 'DeploymentName'

        setParameterValue "CreateResourceGroup" $true
    }

    setParameterValue "ResourceGroupName" $resourceGroupName
}

function chooseDeploymentSize(){
    writeCurrentState
    $deploySizeOptions = "Small (1-100 users)", "Medium (100-1,000 users)", "Large (1,000-10,000 users)", "X-Large (10,000 +)"
    $deploymentSize = promptForChoice "What size enterprise would you like to deploy?" $deploySizeOptions
    setParameterValue "deploymentSize" $deploySizeOptions[$deploymentSize]
}

function showEULA(){
    cls
    
    Write-Host "Thank you for choosing Cireson.\n  This wizard will guide you through installing a new instance of the Cireson Platform, or create a new host on an existing instance of the Cireson Platform."
    Write-Host "The software you are about to install is protected by an End User License Agreement (EULA)."
    Write-Host "By continuing the installation, you are confirming that you have read and understand the EULA."
    
    do{
        $show = promptForChoice "I have read the EULA, and agree to it's terms and conditions." "View EULA", "Agree", "Disagree" 
        if($show -eq 0){
            Start-Process "https://github.com/Cireson/PlatformAzureDeploy/blob/master/Cireson%20-%20End%20User%20License%20Agreement%20-%202016%20v1.4.pdf"
        }

        if ($show -eq 2){
            cls
            Write-Host -ForegroundColor Red "You must agree to the Eula to continue the installation."
            Exit
        }
    }until ($show -eq 1)

}

function chooseCpex(){
    $availCpex = getAvailableCpex

    $cpexOptions = New-Object System.Collections.ArrayList

    foreach($cpex in $availCpex)
    {
        $cpexOptions.Add("$($cpex.Title) - $($cpex.Version)")
    }

    $choices = promptForMultiChoice "Select any CPEX you would like to install." $cpexOptions

    $cpexdefs = @()

    foreach($choice in $choices){
        $cpex = @{
            'Name' = $availCpex[$choice].Title;
            'Version' = $availCpex[$choice].Version;
        }
        $cpexDefs = $cpexDefs + $cpex
    }

    $cpexJson = ConvertTo-Json $cpexDefs -Compress
    setParameterValue "InstallCpex" $cpexJson

}

function chooseName(){
    writeCurrentState
    $name = promptForText "Please enter a name for this deployment.  (This will serve as the VM, SQLServer, etc. base name)"
    setParameterValue "DeploymentName" $name
}

function chooseUserName(){
    writeCurrentState
    $name = promptForText "Please enter an admin username"
    setParameterValue "AdminUserName" $name
}

function choosePassword(){
    $password = Read-Host -Prompt "Please enter an admin password" -AsSecureString
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
}

function choosePlatformVersion(){
    writeCurrentState
    $platformVersions = getPlatformVersions $true

    $platformVersion = promptForChoice "Please select the version of the Platform you wish to install" $platformVersions

    setParameterValue "PlatformVersion" $platformVersions[$platformVersion]
}

function chooseServiceBus(){
    writeCurrentState
    $useExisting = promptForChoice "Would you like to connect to an existing Service Bus, or Create a New one?" "New", "Existing"

    if($useExisting -eq 1){
        $existingSBs = Get-AzureSBNamespace | where {$_.Status -eq "Active"}
        $options = $existingSBs | select -ExpandProperty Name 
        $selectedSb =promptForChoice "Select the Service Bus that you wish to connect this instance to." $options
        setParameterValue "serviceBusConnectionString" $existingSBs[$selectedSb].ConnectionString
        setParameterValue "CreateNewServiceBus" $false
    }else{
        $namespaceValid=$false
        do{
            
            $newSbName = "$(getParameterValue "DeploymentName")sb".ToLower()
        
            $existingNamespace = Get-AzureSBNamespace -Name $newSbName
            if($existingNamespace){
            }else{
                setParameterValue "ServiceBusNamespace" $newSbName
                setParameterValue "CreateNewServiceBus" $true
                $namespaceValid=$true                
            }

        }until($namespaceValid=$true)

    }
}

function chooseLocation(){
    $locations = getLocations
    $location = promptForChoice "Where would you like to install?" $locations

    setParameterValue "Location" $locations[$location]
}

function writeCurrentState(){
	cls
    Write-Host "Current Selections"
	Write-Host "---------------------------------------"
	foreach($parameter in $namedParameters.GetEnumerator()){
        Write-Host "$($parameter.Name): $($parameter.Value)"
	}
	Write-Host "---------------------------------------"
	Write-Host ""
}


function getTemplateParams(){
    $params = @{
        "VMName"="$(getParameterValue 'DeploymentName')VM";
        "vnetName"="$(getParameterValue 'DeploymentName')VNET";
        "adminUserName"="$(getParameterValue 'AdminUserName')";
        "adminPassword"="$adminPassword";
        "vmSize"="Standard_D1";
        "dbName"="CiresonPlatform";
        "platformVersion"="$(getParameterValue 'PlatformVersion')";
        "additionalCpex"="$(getParameterValue 'InstallCpex')";
        "serviceBusConnectionString"="$(getParameterValue 'serviceBusConnectionString')";
        }

    return $params
}

function createResourceGroup(){
	if($namedParameters["CreateResourceGroup"] -eq $true){
        Write-Host "Creating Resource Group $($namedParameters["ResourceGroupName"])"
        $resourceGroup = New-AzureRmResourceGroup -Name $namedParameters["ResourceGroupName"] -Location $namedParameters["Location"]
        Write-Host "Done Creating Resource Group"
    }else{
        $resourceGroup = Get-AzureRmResourceGroup -Name $namedParameters["ResourceGroupName"]
    }


}

function deployServiceBus(){
    if($namedParameters["CreateNewServiceBus"] -eq $true){
		Write-Host "Creating service bus $($namedParameters["ServiceBusNamespace"])"
		#$results = New-AzureSBNamespace -Name $($namedParameters["ServiceBusNamespace"]) -NamespaceType Messaging -Location $namedParameters["Location"] -CreateACSNamespace $false 
        $templateParams = @{"serviceBusNamespace" = "$($namedParameters['ServiceBusNamespace'])"}
        $results = New-AzureRmResourceGroupDeployment -Name "$($namedParameters['DeploymentName'])SB" -ResourceGroupName $namedParameters["ResourceGroupName"] -TemplateUri $serviceBusTemplateUrl -TemplateParameterObject $templateParams
        $namespace = Get-AzureSBNamespace -Name $results.Outputs.namespace.Value
        setParameterValue "serviceBusConnectionString" $namespace.ConnectionString
    }
}

function deployAzure(){
 

    $templateParams = getTemplateParams
    
    Write-Host $templateParams

    Write-Host "Deploying, this may take some time.  You can check the progress of the deployment at https://portal.azure.com"

    $results = New-AzureRmResourceGroupDeployment -Name $namedParameters["DeploymentName"] -ResourceGroupName $namedParameters["ResourceGroupName"] -TemplateUri $deploymentTemplateUrl -TemplateParameterObject $templateParams

    Write-Host "Done Deploying."

    Write-Host "You can view the deployed service here: $($results.PlatformUrl)"
}

function loginToAzureIfNeeded () {
    $Error.Clear()
    Get-AzureRmContext -ErrorAction Continue
    foreach ($errorItem in $Error) {
        if ($errorItem.Exception.ToString() -like "*Run Login-AzureRmAccount to login*") {
            Login-AzureRmAccount
        }
    }
    $Error.Clear();
}


showEula
#
loginToAzureIfNeeded
#
chooseDeploymentSize
#
chooseName
#
chooseLocation
#
chooseSubscription
#
chooseResourceGroup
#
chooseCpex
#
chooseUserName
#
$adminPassword = choosePassword
#
choosePlatformVersion

chooseServiceBus

read-host "We have everything we need, press enter to begin deployment."

createResourceGroup

deployServiceBus

Write-Host (getTemplateParams | ConvertTo-Json)

deployAzure
