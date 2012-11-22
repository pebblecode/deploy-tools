try
{
	$pwd = split-path -parent $MyInvocation.MyCommand.Definition
	
	# import and executre configuration injector
	Import-Module ($pwd + "./ConfigurationInjector.psm1")
	Set-Configuration -WorkingDirectory $pwd

	# install the services
	$command = "Start-Process '$psHome\powershell.exe' -Verb Runas -ArgumentList '" + $pwd + "\installerSub.ps1 -dir " + $pwd + "'"
	Invoke-Expression $command
} 
catch
{
	Write-Error $_.Exception.Message
	exit 1
}