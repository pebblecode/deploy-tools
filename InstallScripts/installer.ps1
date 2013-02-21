try
{
	$baseDir = split-path -parent $MyInvocation.MyCommand.Definition
	
	# import and executre configuration injector
	Import-Module $baseDir\ConfigurationInjector.psm1 -DisableNameChecking
	Set-Configuration -WorkingDirectory $baseDir
	
	$installScript = (Resolve-Path "$baseDir\installerSub.ps1").Path

	$baseDir = $baseDir -replace " ", "`` "
	$installScript = $installScript -replace " ", "`` "

	# install the services
	$command = "Start-Process '$psHome\powershell.exe' -Verb Runas -ArgumentList '" + $installScript + " -dir " + $baseDir + "'"

	Write-Host $command 
	Invoke-Expression $command
} 
catch
{
	Write-Error $_.Exception.Message
	exit 1
}