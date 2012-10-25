$pwd = [System.IO.Directory]::GetCurrentDirectory().Replace(" ","`` ")

# import and executre configuration injector
Import-Module ./ConfigurationInjector.dll 
Set-Configuration -WorkingDirectory $pwd

# install the services
#$command = "Start-Process '$psHome\powershell.exe' -Verb Runas -ArgumentList '" + $pwd + "\installerSub.ps1 -dir " + $pwd + "'"
#Invoke-Expression $command
