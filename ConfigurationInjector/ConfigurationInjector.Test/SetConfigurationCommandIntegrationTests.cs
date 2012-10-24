using System;
using System.IO;
using System.Management.Automation.Runspaces;
using System.Xml;
using System.Xml.Linq;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace ConfigurationInjector.Test
{
    /// <summary>
    /// Contains integration test for the Set-Configuration powershell command
    /// </summary> 
    [TestClass]
    public class SetConfigurationCommandIntegrationTests
    {

        [TestMethod]
        [DeploymentItem("settings.xml")]
        [DeploymentItem("Bingo.config")]
        [DeploymentItem("Bingo.config.map.xml")]
        [DeploymentItem("Bingo.config.expected")]
        [DeploymentItem("SGPCore.config")]
        [DeploymentItem("SGPCore.config.expected")]
        [DeploymentItem("SGPCore.config.map.xml")]
        [DeploymentItem("System.Management.dll")]
        [DeploymentItem("System.Management.Automation.dll")]
        [DeploymentItem("ConfigurationInjector.dll")]
        [DeploymentItem("XML Schemas\\", "XML Schemas")]
        public void SetConfiguration_TryInjectionMultipleFiles_FilesAreUpdated()
        {
            // Arrange
            var scriptText = String.Format(
                @"
                Import-Module ""{0}ConfigurationInjector.dll""
                Set-Configuration -WorkingDirectory ""{0}""
            ", GetAssemblyPath());

            // Act
            try
            {
                // try-catch block, because powershell errors are thrown from the runspace
                RunScript(scriptText);
            }
            catch (Exception exception)
            {
                Assert.Fail(exception.Message);
            }


            // Assert
            AssertIfConfigurationIsAsExpected("SGPCore.config.expected", "SGPCore.config");
            AssertIfConfigurationIsAsExpected("Bingo.config.expected", "Bingo.config");
        }

        private void AssertIfConfigurationIsAsExpected(string expectedfileName, string resultfileName)
        {
            var expected = XDocument.Load(GetAssemblyPath() + expectedfileName).ToString();
            var result = XDocument.Load(GetAssemblyPath() + resultfileName).ToString();

            Assert.AreEqual(expected, result);
        }

        private string ReplaceLineFeeds(string input)
        {
            return input.Replace(" ", string.Empty).Replace("\n", string.Empty).Replace("\r\n", string.Empty).Replace("\r", string.Empty);
        }

        private string GetAssemblyPath()
        {
            var codeBase = System.Reflection.Assembly.GetExecutingAssembly().Location;
            var directory = Path.GetDirectoryName(codeBase);
            return directory + "\\";
        }

        private void RunScript(string scriptText)
        {
            // create Powershell runspace
            Runspace runspace = RunspaceFactory.CreateRunspace();
            runspace.Open();

            // create a pipeline and feed it the script text
            Pipeline pipeline = runspace.CreatePipeline();
            pipeline.Commands.AddScript(scriptText);
            pipeline.Commands.Add("Out-String");

            // execute the script
            pipeline.Invoke();

            // close the runspace
            runspace.Close();
        }
    }
}

