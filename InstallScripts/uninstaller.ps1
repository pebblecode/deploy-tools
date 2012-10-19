$pwd = [System.IO.Directory]::GetCurrentDirectory().Replace(" ","`` ")
$command = "Start-Process '$psHome\powershell.exe' -Verb Runas -ArgumentList '" + $pwd + "\uninstallerSub.ps1 -dir " + $pwd + "'"
echo $command 
Invoke-Expression $command 
