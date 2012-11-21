# Command to inject configuration located at "settings.xml" in XXX.exe.config files, using the XXX.config.map.xml
Function Set-Configuration
{
    param (
        [string] $workingDirectory
    )

	try
	{

		# define configuration constants
		$settingsFileName = "settings.xml"
		$mappingFilesSuffix = ".map.xml"
		$configFilesSuffix = ".config"

		# add slash to the end of the directory name if none 
		if (!$workingDirectory.EndsWith("\")){ $workingDirectory = $workingDirectory + "\" }

		# check if working directory exists
		CheckIfWorkingDirectoryExists

		# check if settings file exists
		CheckIfSettingsFileExists

		# inject files
		InjectFiles
		
	} catch {
		Write-Error $_.Exception.Message
		exit 1
	}
}
Function InjectFiles()
{	
		$mappingFiles = [IO.Directory]::GetFiles($workingDirectory,  "*" + $mappingFilesSuffix); 
		foreach($mappingFile in $mappingFiles)
	    { 
			try {
				
				InjectFile $mappingFile
			
			# continue if config file for the mapping file does not exist 
			} catch [System.IO.FileNotFoundException]{
				continue
			}
			# throw if any other error
			catch [System.Exception]
			{	
				throw $_.Exception
			}
	        
	    }     
}
Function InjectFile([string]$mappingFile){

	$configFile = ExtractConfigFileName($mappingFile)
	if (![IO.File]::Exists($configFile))
	{
		throw New-Object System.IO.FileNotFoundException ""
	}
	
	$mappingDoc = [xml](Get-Content $mappingFile)
	$settingsDoc = [xml](Get-Content (GetFullPath($settingsFileName)))
	$configDoc = [xml](Get-Content $configFile)
	
	$mapElements = $mappingDoc.mappings.map
	
	foreach ($mapElement in $mapElements)
	{
		$key = $mapElement.key
		$mapToElements = $mapElement.SelectNodes("to")
		
		foreach ($mapToElement in $mapToElements)
		{
			InjectValue $key $mapToElement."#text".ToString()
		}
	}
	
	# save file
	$configDoc.Save($configFile)
}
Function InjectValue($key, $mapToElement)
{
	$value = $settingsDoc.envConfig.$key
	$toElements = $configDoc | Select-Xml -XPath $mapToElement
	foreach($elem in $toElements)
	{
		$elem.Node.set_Value($value)
	}
}
Function ExtractConfigFileName([string]$mappingFile)
{
	[string]$mappingFileName = [IO.Path]::GetFileName($mappingFile)	
	[string]$configFileName = $workingDirectory + $mappingFileName.Replace($mappingFilesSuffix, $configFilesSuffix)
	
	return $configFileName
}
Function CheckIfWorkingDirectoryExists()
{
	if (![IO.Directory]::Exists($workingDirectory))
	    {
	        $error = ("Working directory " + $workingDirectory + " not found.")
	        throw $error
	    }
}
Function CheckIfSettingsFileExists()
{
	$configFile = GetFullPath($settingsFileName)
	 
	 if (![IO.File]::Exists($configFile))
	    {
	        $error = ("Required config file '" +  $configFile + "' was not found.")
	        throw $error
	    }
}
Function GetFullPath([string]$relativePath)
{
	[string]$fullPath = $workingDirectory + $relativePath
	return $fullPath
}


# define public functions
export-modulemember Set-Configuration