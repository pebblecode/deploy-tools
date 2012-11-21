# This is a tool needed to handle configuration differenties when deploying any application to a specific environment. It injects configuration values in [FooAssembly].config files from "settings.xml", using the [FooAssembly].map.xml.
It relies to the existence of those 3 files for any injection.

## settings.xml

"settings.xml" is an environment specific file with configuration values. It contains the configuration for all the products that need to be installed on that particular environment.
See [this](https://github.com/BedeGaming/config/blob/develop/staging/37.188.117.219/settings.xml) for an example.
settings.xml should have the following structure:
	
	<envConfig>
		<foo-key1>foo-value1</foo-key1>
		<foo-key2>foo-value2</foo-key2>
		..
	</envConfig>

## [FooAssembly].map.xml

This xml file defines the way that environmental specific values in "settings.xml" will be mapped to the application configuration file.
See [this](https://github.com/BedeGaming/sgp-core/blob/develop/src/SGP.Wallet.Service/SGP.Wallet.Service.exe.map.xml) for an example.

	<mappings>
	  <map key="foo-key-from-settings-file">
		<to>xpath/to/foo/element/in/application/configuration/file[@occurence="1"]</to>
		<to>xpath/to/foo/element/in/application/configuration/file[@occurence="2"]</to>
		..
	  </map>
	  ..
	</mappings>
	
## [FooAssembly].config

It's the application configuration file.

