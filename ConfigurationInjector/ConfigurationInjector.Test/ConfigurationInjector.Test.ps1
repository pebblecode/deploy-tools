# Script to test the Configuration.Injector.psm1 module

# define paths
$pwd = split-path -parent $MyInvocation.MyCommand.Definition
$testDirectoryPath = $pwd + "\ConfigurationInjector.Test.Resources"
$tempDirectoryPath = $pwd + "\" + (Get-Random).ToString()

# define tests
function SetConfiguration_ValidMappingFiles_Valid ([string]$testFile)
{
	try
	{
		# Arrange
		
			# create temp dir and copy all the test resources to it
			New-Item -ItemType directory -Path $tempDirectoryPath
			Copy-Item ($testDirectoryPath + "\*") $tempDirectoryPath
			
			# import configuration injector
			Import-Module ../ConfigurationInjector.psm1
			
		# Act
			Set-Configuration -WorkingDirectory $tempDirectoryPath

		# Assert
			AssertConfigFilesAreEqual $testFile
		
			PassOrFailMessage $true ("SetConfiguration_ValidMappingFiles_Valid for " + $testFile)
	}
	catch 
	{
		PassOrFailMessage $false "SetConfiguration_ValidMappingFiles_Valid"
		Write-Error $_.Exception.Message
		exit 1
	}
	finally
	{
		Remove-Item -Recurse -Force $tempDirectoryPath
		Remove-Module ConfigurationInjector	
	}
}
function SetConfiguration_WrongWorkingDirectory_NotFoundException
{
	try
	{
		# Arrange
		
			# create temp dir and copy all the test resources to it
			New-Item -ItemType directory -Path $tempDirectoryPath
			Copy-Item ($testDirectoryPath + "\*") $tempDirectoryPath
			
			$dummyDirName = "C:\PathToNowhere\"
			
			# import configuration injector
			Import-Module ../ConfigurationInjector.psm1
			
		# Act
			Set-Configuration -WorkingDirectory $dummyDirName
		
		#Assert
			# should not reach the assertions
			PassOrFailMessage $false "SetConfiguration_WrongWorkingDirectory_NotFoundException"
			exit 1
		
	}
	catch 
	{
		# Assert
			$actualException = $_.Exception.Message
			$expectedException = "Working directory " + $dummyDirName + " not found."
			if ($actualException -ne $expectedException)
			{	
				PassOrFailMessage $false "SetConfiguration_WrongWorkingDirectory_NotFoundException"

			} else 
			{
				PassOrFailMessage $true "SetConfiguration_WrongWorkingDirectory_NotFoundException"
			}
	}
	finally
	{
		Remove-Item -Recurse -Force $tempDirectoryPath
		Remove-Module ConfigurationInjector	
	}
}
function SetConfiguration_NoSettingsFile_NotFoundException
{
	try
	{
		# Arrange
		
			# create temp dir and copy all the test resources to it
			New-Item -ItemType directory -Path $tempDirectoryPath
			Copy-Item ($testDirectoryPath + "\*") $tempDirectoryPath
			Remove-Item ($tempDirectoryPath + "\settings.xml")
			
			# import configuration injector
			Import-Module ../ConfigurationInjector.psm1
			
		# Act
			Set-Configuration -WorkingDirectory $tempDirectoryPath
			
		#Assert
			# should not reach the assertions
			PassOrFailMessage $false "SetConfiguration_NoSettingsFile_NotFoundException"
			exit 1

	}
	catch 
	{
		# Assert
		$actualException = $_.Exception.Message
		$expectedException = "Required config file '" +  $tempDirectoryPath + "\settings.xml' was not found."
		if ($actualException -ne $expectedException)
		{	
			PassOrFailMessage $false "SetConfiguration_NoSettingsFile_NotFoundException"

		} else 
		{
			PassOrFailMessage $true "SetConfiguration_NoSettingsFile_NotFoundException"
		}
	}
	finally
	{
		Remove-Item -Recurse -Force $tempDirectoryPath
		Remove-Module ConfigurationInjector	
	}
}
function SetConfiguration_NoConfigFileForMappingFile_NoError
{
	try
	{
		# Arrange
		
			# create temp dir and copy all the test resources to it
			New-Item -ItemType directory -Path $tempDirectoryPath
			Copy-Item ($testDirectoryPath + "\*") $tempDirectoryPath
			New-Item -ItemType file -Path ($tempDirectoryPath + "\NoConfigFileForMappingFile.map.xml")
			
			# import configuration injector
			Import-Module ../ConfigurationInjector.psm1
			
		# Act
			Set-Configuration -WorkingDirectory $tempDirectoryPath

		# Assert	
			PassOrFailMessage $true ("SetConfiguration_NoConfigFileForMappingFile_NoError")
	}
	catch 
	{
		PassOrFailMessage $false "SetConfiguration_NoConfigFileForMappingFile_NoError"
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
function PassOrFailMessage([bool]$Passed, [string]$testName)
{
	if($Passed)
	{
		Write-Host ("Test '" + $testName + "' passed successfully!")
	}
	else 
	{
		Write-Error ("Test '" + $testName + "' failed")
	}
	
}
# execute tests
SetConfiguration_ValidMappingFiles_Valid "SimpleInjection.config"
SetConfiguration_ValidMappingFiles_Valid "OneValueToMultipleKeys.config"
SetConfiguration_ValidMappingFiles_Valid "IntraFileReferencing.config"
SetConfiguration_NoConfigFileForMappingFile_NoError
SetConfiguration_WrongWorkingDirectory_NotFoundException
SetConfiguration_NoSettingsFile_NotFoundException