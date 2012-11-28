Function RemoteInstall
{
   param ([string] $remotePC, [string] $azureConnectionString, [string] $artifiactName, [string] $containerName, [string] $settings)   
     
    $params = $remotePC, $azureConnectionString,$artifiactName,$containerName,$settings
    $remoteSession = new-pssession -computerName $remotePC

    invoke-command -session $remoteSession -ArgumentList $params -ScriptBlock {      
       try
       {
            mkdir -ErrorAction SilentlyContinue "C:\BEDE\Temp"
	        Set-Location "C:\BEDE\Temp"

            #Download File
            $ZipName = "Artifacts.zip"
            $file = "C:\BEDE\Temp\" + $ZipName
            Import-Module "C:\Windows\System32\AzureHelper.dll"
            Get-AzureBlobDownload -ConnectionString $args[1] -RemoteFileName $args[2] -ContainerName $args[3] -LocalFileName $file
    
            #Unzip it 
            $shell_app=new-object -com shell.application
            $zip_file = $shell_app.namespace($file)
            $destination = $shell_app.namespace((Get-Location).Path) 
            $destination.Copyhere($zip_file.items())

            #Make the settings file
            $args[4] > settings.xml

            #Run Installer 
            Invoke-Expression ("C:\BEDE\Temp\UnInstallerSub.ps1 -dir C:\BEDE\Temp")
            Invoke-Expression ("C:\BEDE\Temp\InstallerSub.ps1 -dir C:\BEDE\Temp")

            #Clear the temp directory
            get-childitem "C:\BEDE\Temp" -recurse | remove-item -recurse 
        }
        finally
        {        
            Exit-PSSession 
        }
    }
}


export-modulemember RemoteInstall