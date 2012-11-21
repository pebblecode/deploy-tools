# Script to test the Configuration.Injector.psm1 module

# define paths
$pwd = split-path -parent $MyInvocation.MyCommand.Definition
$testDirectoryPath = $pwd + "\ConfigurationInjector.Test.Resources"
$tempDirectoryPath = $pwd + "\" + (Get-Random).ToString()

# define test
function TestConfigurationInjector
{
	try
	{
		# Arrange
		
			# create temp dir and copy all the test resources to it
			New-Item -ItemType directory -Path $tempDirectoryPath
			Copy-Item ($testDirectoryPath + "\*") $tempDirectoryPath
			
			# import configuration injector
			Import-Module ./ConfigurationInjector.psm1
			
		# Act
			Set-Configuration -WorkingDirectory $tempDirectoryPath

		# Assert
			AssertConfigFilesAreEqual "SGPCore.config"
			AssertConfigFilesAreEqual "Bingo.config"
			AssertConfigFilesAreEqual "Bally.config"
			AssertConfigFilesAreEqual "GameLaunch.config"
			
	}
	catch 
	{
		Write-Error $_.Exception.Message
		exit 1
	}
	finally
	{
		Remove-Item -Recurse -Force $tempDirectoryPath
		Remove-Module ConfigurationInjector	
	}
}
# define helper function
function AssertConfigFilesAreEqual([string]$configFileName)
{
	$actual = [xml](Get-Content ($tempDirectoryPath + "\" + $configFileName))
	$expected = [xml](Get-Content ($tempDirectoryPath + "\" + $configFileName + ".expected"))
	if (!($actual.InnerXml -eq $expected.InnerXml)){
		throw $configFileName + " file injection failed"
	} 
}

# execute test
TestConfigurationInjector