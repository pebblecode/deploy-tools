

#This function will create an install directory, in D:\<environment name>\<component> (overwriting any existing content)
#It will also create a logs directory in D:\<environment name>\Logs
#Then it will install the core service.	
#Dependencies are; valid config file, .netfamework 4.0 and Administrator previlidges
Function InstallService
{
    param ([string] $rootInstallDirectory,[string] $baseServiceName, [string] $installerFile)


    $configFile =  [System.IO.Directory]::GetCurrentDirectory() + "\settings.xml"
    if(!$configFile)
    {
        $error = ("Required config file" +  $configFile + "was not found.")
        throw $error
    }

    $instalUtilPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe"
    if (![IO.File]::Exists($instalUtilPath))
    {
        throw "InstallUtil not present. Check .net framework 4 is installed"
    }
    echo ('load config file from' +$configFile)
    $xml = [xml](Get-Content $configFile)
    $xpath = "/envConfig/environment.name"
    $environmentName = $xml.SelectSingleNode($xpath).value
    echo ("environment loaded as " + $environmentName)
        
    $serviceName = $baseServiceName + ' ' + $environmentName
    echo ("checking installed service, " + $serviceName)
    $service = Get-Service $serviceName -ErrorAction SilentlyContinue 
    if($service)
    {
        throw "Service already installed. Please uninstall if you wish to continue"
    }  
         
    $targetDir = $rootInstallDirectory + $environmentName + "\" + $baseServiceName 
    $currentDir = [System.IO.Directory]::GetCurrentDirectory()

    #Create Logs directory if dosent exist
    New-Item -ItemType directory -Path ($rootInstallDirectory + $environmentName + "\Logs") -ErrorAction SilentlyContinue

    if($currentDir -ne $targetDir)
    {
        echo ("Creating install directory at " + $targetDir)
        #Clear the old path if it exists
        Remove-Item -path $targetDir -ErrorAction SilentlyContinue -recurse 
        New-Item -ItemType directory -Path $targetDir -ErrorAction SilentlyContinue 
        Copy-Item ($currentDir + "\*") $targetDir -recurse
    }
    else
    {
        echo("Running install from target directory. No need to create any directories");
    }

    #Install the service and turn it on 
    $commmand =$instalUtilPath + (" /i" + " /environment="+$environmentName + ' "' + $targetDir +"\" + $installerFile+ '"')
    echo ("Running " + $commmand)
    Invoke-Expression $commmand
    echo "Installed, starting service"
    Start-Service -displayname ($baseServiceName + " "+ $environmentName)
    echo "Install complete"

}

#This function will remove the given service.It moves files to a backup directory
#Dependencies are a valid config file and .net framework 4.0
Function UnInstallService
{
    param ([string] $rootInstallDirectory,[string] $baseServiceName, [string] $installerFile)

    $configFile =  [System.IO.Directory]::GetCurrentDirectory() + "\"+ $installerFile + ".config"
    $environmentalSettings =  [System.IO.Directory]::GetCurrentDirectory() + "\settings.xml"
    if(!$configFile)
    {
        throw "Required app config file was not found."
    }

    if(!$environmentalSettings)
    {
        throw "Required config file with environmental settings was not found."
    }

    $instalUtilPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe"
    if (![IO.File]::Exists($instalUtilPath))
    {
        throw "InstallUtil not present. Check .net framework 4 is installed"
    }

    $xml = [xml](Get-Content $environmentalSettings)
    $xpath = "/envConfig/environment.name"
    $environmentName = $xml.SelectSingleNode($xpath).value
    echo ("environment loaded as " + $environmentName)

    $xml = [xml](Get-Content $configFile)
    $xpath = "/configuration/appSettings/add[@key='app.version']"
    $version = $xml.SelectSingleNode($xpath).value
    echo ("version loaded as " + $version)
        
    $serviceName = $baseServiceName + ' ' + $environmentName
    $service = Get-Service $serviceName -ErrorAction SilentlyContinue 
    if(!$service)
    {
        throw "Service not installed. Cannot continue"
    }

    $targetDir = $rootInstallDirectory + $environmentName + "\" + $baseServiceName     
    #Remove the service
    $commmand =$instalUtilPath + (" /u" + " /environment="+$environmentName + ' "' + $targetDir +"\" + $installerFile+ '"')
    Invoke-Expression $commmand

    $backupDir = $rootInstallDirectory + "Backup\" + $environmentName +"\" + $baseServiceName + "\" + $version
    echo ("making a backup of " + $targetDir + " in " + $backupDir)
    New-Item -ItemType directory -Path $backupDir -ErrorAction SilentlyContinue



    #NB. Remove-item not used because of bug http://serverfault.com/questions/199921/powershell-remove-force
    cp $targetDir $backupDir -force -recurse
    get-childitem $targetDir -recurse | remove-item -recurse

    echo "service uninstalled"
}

export-modulemember UnInstallService
export-modulemember InstallService