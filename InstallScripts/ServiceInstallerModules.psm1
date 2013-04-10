

#This function will create an install directory, in D:\<environment name>\<component> (overwriting any existing content)
#It will also create a logs directory in D:\<environment name>\Logs
#Then it will install the core service.	
#Dependencies are; valid config file, .netfamework 4.0 and Administrator previlidges
Function InstallService
{
    [CmdletBinding()] 
    PARAM ( 
        [Parameter(Mandatory=$True, HelpMessage="Root install directory")] [String] $rootInstallDirectory,
        [Parameter(Mandatory=$True, HelpMessage="Base service Name")] [String] $baseServiceName,
        [Parameter(Mandatory=$True, HelpMessage="Installer file")] [String] $installerFile,
        [Parameter(Mandatory=$false, HelpMessage="Start service")] [bool] $startService = 1
    ) 
   
    PROCESS {
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
    $environmentName = $xml.SelectSingleNode($xpath)."#text"
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
    if($startService)
    {
        echo "Starting service"
        Start-Service -displayname ($baseServiceName + " "+ $environmentName)
    }
    echo "Install complete"
  }
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
    $environmentName = $xml.SelectSingleNode($xpath)."#text"
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

#This function will perfom a few tests to enusure the basic health of an installed service
Function SmokeTestBingoService
{
    [CmdletBinding()] 
    PARAM ([Parameter(Mandatory=$True, HelpMessage="Path to the service")] [String] $Path)

    echo ("running smoke test on "+  $Path)
    Set-Location ([string] $Path)

    #Check for presence of log file _engine.log
    CheckFileExistsOrDie ("..\Logs\_engine.log")
    $engineLog =([string](Get-Content "..\Logs\_engine.log"))

    #Check for absence of error log file _engine_errors.log
    CheckFileAbsentOrDie("..\Logs\_engine_errors.log")

    #Check for absence of logging error file exceptionDump.txt (occurs in binaries install dir, not logs subdirectory)
    CheckFileAbsentOrDie("exceptionDump.txt")

   echo ('engine Log file data loaded as :' + $engineLog)

   # Check the _engine.log to ensure a game has been scheduled, by checking for presence of the following log messages:
   #31-01 09:05:06    Scheduler       Info      SCHED,ID:076741 EVENT,ID:088541 Event created
   #31-01 09:05:06    Scheduler       Info      SCHED,ID:076741 EVENT,ID:088541 Starting game.
   #31-01 09:05:06    Scheduler       Info      SCHED,ID:076741 ROOM,ID:000031 Opening room

   $eventCreatedRegex = '[0-9][0-9]-[0-9][0-9].[0-9][0-9]:[0-9][0-9]:[0-9][0-9].*Scheduler.*SCHED,ID:[0-9]*.EVENT,ID:[0-9]*.Event.created'
   IsRegexMatchOrDie $engineLog $eventCreatedRegex 

   $startingGameRegex = '[0-9][0-9]-[0-9][0-9].[0-9][0-9]:[0-9][0-9]:[0-9][0-9].*Scheduler.*SCHED,ID:[0-9]*.EVENT,ID:[0-9]*.Starting.game'
   IsRegexMatchOrDie $engineLog $startingGameRegex

   $OpenRoomRegex = '[0-9][0-9]-[0-9][0-9].[0-9][0-9]:[0-9][0-9]:[0-9][0-9].*Scheduler.*SCHED,ID:[0-9]*.ROOM,ID:[0-9]*.Opening.room'
   IsRegexMatchOrDie $engineLog $OpenRoomRegex

   echo "All smoke tests passed successfully! http://img.xzoom.in/21processed/success%20kid.jpg"
}

Function CheckFileAbsentOrDie($fileName)
{
    echo ("Checking for presence of " + $fileName)
    if(!(Test-Path $fileName)){
        echo ($fileName + "does not exists")
    }
    else {
       $data =([string](Get-Content $fileName))
       echo ($fileName + ' data is ' + $data)
       throw ($fileName + " exists! Test failure");
    }
}


Function IsRegexMatchOrDie($text,$regex)
{
    echo ("Checking for regex match " + $regex)
    if($text -match $regex){
     echo ("match")
    }
    else{
       throw ($regex + " no match! Test failure");
    }
}

Function CheckFileExistsOrDie($fileName)
{
    echo ("Checking for presence of " + $fileName)
    if(Test-Path $fileName){
        echo ($fileName + " exists")
    }
    else {
       throw ($fileName + " does not exist! Test failure");
    }
}
export-modulemember SmokeTestBingoService
export-modulemember UnInstallService
export-modulemember InstallService