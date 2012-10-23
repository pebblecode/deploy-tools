using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Xml;
using System.Xml.Linq;
using System.Xml.Schema;
using System.Xml.XPath;

namespace ConfigurationInjector
{
    /// <summary>
    /// Class to create a powershell comand, that injects configuration located at "settings.xml" in XXX.exe.config files, using the XXX.config.map.xml
    /// </summary> 
    [System.Management.Automation.Cmdlet(System.Management.Automation.VerbsCommon.Set, "Configuration")]
    public class SetConfigurationCommand : System.Management.Automation.PSCmdlet
    {
        [System.Management.Automation.Parameter(Mandatory = true, Position = 0, HelpMessage = "The directory of the configuration files.")]
        public string WorkingDirectory;

        private string WorkingDirectoryFormatted
        {
            get { return WorkingDirectory.EndsWith("\\") ? WorkingDirectory : WorkingDirectory + "\\"; }
        }

        private string AssemblyPath
        {
            get
            {
                return Path.GetDirectoryName(
                   System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\";
            }
        }

        private XDocument _settings;

        protected override void BeginProcessing()
        {
            LoadSettingsFile();

            ValidateDocAgaisntSchema(_settings, Configuration.SettingsSchemaPath, "settings.xml");

            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            string[] fileNames = Directory.GetFiles(WorkingDirectoryFormatted, "*" + Configuration.MappingFilesSuffix);

            foreach (var fileName in fileNames)
            {
                ProcessMapFile(fileName);
            }
        }

        private void ProcessMapFile(string fileName)
        {
            // Get map document
            XDocument mapDoc = XDocument.Load(fileName);

            // Validate it
            ValidateDocAgaisntSchema(mapDoc, Configuration.MapSchemaPath, System.IO.Path.GetFileName(fileName));

            // Get config document
            XDocument configDoc = LoadConfigurationFile(fileName);
            
            // Inject the configuration from settings.xml
            InjectConfiguration(mapDoc, configDoc);

            // Save
            SaveConfigurationFile(configDoc, fileName);
        }

        private void SaveConfigurationFile(XDocument configDoc, string mapfileName)
        {
            var configFileName = GetConfigFileName(mapfileName);
            
            configDoc.Save(configFileName, SaveOptions.None);
        }

        private void ValidateDocAgaisntSchema(XDocument doc, string schemaPath, string fileName)
        {
            if (!IsXDocumentValid(doc, schemaPath))
            {
                throw new InvalidDataException(String.Format("'{0}' is not in the correct format!", fileName));
            }
        }

        private void InjectConfiguration(XDocument mapDoc, XDocument configDoc)
        {
            foreach (var element in mapDoc.Descendants("map"))
            {
                XAttribute key = element.Attribute("key");
                var mapToElements = element.Descendants("to");

                foreach (var mapToElement in mapToElements)
                {
                    PerformSingleInjection(configDoc, key.Value, mapToElement.Value);
                }
            }

        }

        private void PerformSingleInjection(XDocument targetConfiguration, string settingsKey, string toXPath)
        {
            var settings = _settings.Descendants(settingsKey);
            if (settings.Any())
            {
                var setting = settings.First();
                IEnumerable xPathEvaluate = (IEnumerable)targetConfiguration.XPathEvaluate(toXPath);
                xPathEvaluate.OfType<XElement>().ToList().ForEach(x => x.Value = setting.Value);
                xPathEvaluate.OfType<XAttribute>().ToList().ForEach(x => x.Value = setting.Value);    
            }
        }

        private XDocument LoadConfigurationFile(string mapfileName)
        {
            var configFileName = GetConfigFileName(mapfileName);

            if (File.Exists(configFileName))
            {
                return XDocument.Load(configFileName);
            }

            throw new FileNotFoundException(string.Format("Config file '{0}' not found!", configFileName));
        }

        private string GetConfigFileName(string mapfileName)
        {
            var baseString = mapfileName.Replace(Configuration.MappingFilesSuffix, String.Empty);
            string configFileName = baseString + Configuration.ConfigurationFilesSuffix;

            return configFileName;
        }

        private bool IsXDocumentValid(XDocument doc, string schemaPath)
        {
            XmlSchemaSet schemaSet = new XmlSchemaSet();
            XmlTextReader reader = new XmlTextReader(AssemblyPath + schemaPath);
            XmlSchema schema = XmlSchema.Read(reader, null);
            schemaSet.Add(schema);

            bool errors = false;
            doc.Validate(schemaSet, (o, e) =>
            {
                Console.WriteLine("{0}", e.Message);
                errors = true;
            }, true);

            return !errors;
        }

        private void LoadSettingsFile()
        {
            var filePath = WorkingDirectoryFormatted + Configuration.SettingsFile;
            if (File.Exists(filePath))
            {
                _settings = XDocument.Load(filePath);
            }
            else
            {
                throw new FileNotFoundException("Enviroment based file named 'settings.xml' should be placed in the folder where the configuration should be injected");
            }
        }
    }
}
