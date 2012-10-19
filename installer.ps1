$pwd = [System.IO.Directory]::GetCurrentDirectory().Replace(" ","`` ")
$command = "Start-Process '$psHome\powershell.exe' -Verb Runas -ArgumentList '" + $pwd + "\installerSub.ps1 -dir " + $pwd + "'"
Invoke-Expression $command
