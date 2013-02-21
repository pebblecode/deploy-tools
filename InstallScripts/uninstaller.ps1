try
{
	$baseDir = split-path -parent $MyInvocation.MyCommand.Definition
	$uninstallScript = (Resolve-Path "$baseDir\uninstallerSub.ps1").Path
	
	$baseDir = $baseDir -replace " ", "`` "
	$uninstallScript = $uninstallScript -replace " ", "`` "

	$command = "Start-Process '$psHome\powershell.exe' -Verb Runas -ArgumentList '" + $uninstallScript + " -dir " + $baseDir + "'"
	
	Write-Host $command 
	Invoke-Expression $command 
}
catch
{
	Write-Error $_.Exception.Message
	exit 1
}