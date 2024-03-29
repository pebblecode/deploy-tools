# Command to inject configuration located at "settings.xml" in [FooAssembly].config files, using the [FooAssembly].map.xml
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
		throw $_.Exception.Message
		# commented out, because error handling is left to the caller
		#exit 1
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
	$value = GetValue($key) 
	$toElements = $configDoc | Select-Xml -XPath $mapToElement
	foreach($elem in $toElements)
	{
		if ($elem -ne $null)
		{
			$elem.Node.set_Value($value)
		} 
		else 
		{
			$warning = "Value for '" + $key + "' can't be injected (Check if following xpath '" + $mapToElement + "' has a valid match in '" + $configFile + "')"
			Write-Warning $warning
		}
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
Function GetValue($key)
{
	[string]$value = $settingsDoc.envConfig.$key
	
	# if value contains references to other elements -> replace them in the value string
	
	#$value -match "\$[^\$]+\$"
	
	$matches = [regex]::Matches($value, "\$[^\$]+\$")
	
	if ($matches.Count -gt 0)
	{
		for ($i = 0; $i -lt $matches.Count; $i++)
		{
			$refElem = $matches[$i].Value.Replace("$", "")
			$refElemValue = $settingsDoc.envConfig.$refElem
			$value = $value.Replace($matches[$i].Value, $refElemValue)
		}
	}
	
	return $value
}

# define public functions
export-modulemember Set-Configuration