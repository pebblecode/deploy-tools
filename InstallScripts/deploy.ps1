Function Deploy
{
 ##param (
 ##[Parameter(Mandatory=$true)]
 ##[string] $enviroment,
## [Parameter(Mandatory=$true)]
## [string] $artifiactName
## )   
  $enviroment = "development"
  $artifiactName = "sgp_1.3.1.200.zip"

    Import-Module ".\remoteDeployModules.psm1"
    $azureConnectionString = "DefaultEndpointsProtocol=https;AccountName=pebbledeploybucket;AccountKey=V4K6iBIbAdDsoQ/Ly7RBpEF8dFvtOdRomFV4a80hxzp5eTxBaOwbkUSE2IELSV+f+5ZG9KVobY7WR/Yy3dABAA=="
    $containerName = "testbucket"
    Import-Module "C:\Windows\System32\AzureHelper.dll"

    #Upload the artifact to the blob store to use later
    Push-AzureBlobUpload -ContainerName $containerName -ConnectionString $azureConnectionString -LocalFileName $artifiactName

    #Replace config with latest from git
    rm config -Recurse -Force  -ErrorAction SilentlyContinue
    git clone git@github.com:BedeGaming/config.git  -b powershell-remote-deploy-scripts 

    #Loop through each settings folder in the enviroment and install the service
    $settingsFolder = ("config\"+$enviroment)
    foreach ($serverName in (Get-ChildItem -Path $settingsFolder)){

        Write-Host ("Deploying to " + $serverName)
        $settings = Get-Content ("config\"+$enviroment +"\" + $serverName + "\settings.xml")
        RemoteInstall -remotePC $serverName -azureConnectionString $azureConnectionString -artifiactName $artifiactName -containerName $containerName -settings $settings
    }
}

try{
    Deploy
}catch{
	Write-Error $_.Exception.Message
Read-Host
	exit 1

}
