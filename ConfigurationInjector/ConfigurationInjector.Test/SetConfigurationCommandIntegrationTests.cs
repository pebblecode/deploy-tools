using System;
using System.IO;
using System.Management.Automation.Runspaces;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace ConfigurationInjector.Test
{
    /// <summary>
    /// Contains integration test for the Set-Configuration powershell command
    /// Test are commented out, because file system dependancies are not thread safe 
    /// (if you execute tests one by one -> it's all fine, but if all together -> KABOOM)
    /// </summary> 
    [TestClass]
    [DeploymentItem("System.Management.dll")]
    [DeploymentItem("System.Management.Automation.dll")]
    [DeploymentItem("ConfigurationInjector.dll")]
    [DeploymentItem("XML Schemas\\", "XML Schemas")]

    public class SetConfigurationCommandIntegrationTests
    {

        [TestMethod]
        [DeploymentItem("settings.xml")]
        [DeploymentItem("Bingo.config")]
        [DeploymentItem("Bingo.config.map.xml")]
        [DeploymentItem("Bingo.config.expected")]
        [DeploymentItem("test.config")]
        [DeploymentItem("test.config.expected")]
        [DeploymentItem("test.config.map.xml")]
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
            AssertIfConfigurationIsAsExpected("test.config.expected", "test.config");
            AssertIfConfigurationIsAsExpected("Bingo.config.expected", "Bingo.config");
        }

        #region Commented out tests, because of not thread safe execution
        
        //        [TestMethod]
//        public void SetConfiguration_NoSettingsFIle_ErrorThrown()
//        {
//            // Arrange
//            var scriptText = String.Format(
//                @"
//                Import-Module ""{0}ConfigurationInjector.dll""
//                Set-Configuration -WorkingDirectory ""{0}""
//            ", GetAssemblyPath());

//            // Act
//            try
//            {
//                // try-catch block, because powershell errors are thrown from the runspace
//                RunScript(scriptText);

//                // Assert
//                Assert.Fail("An exception should be thrown by powershell module!");
//            }
//            catch (Exception exception)
//            {
//                Assert.AreEqual(
//                    "Enviroment based file named 'settings.xml' should be placed in the folder where the configuration should be injected",
//                    exception.Message);
//            }
//        }

//        [TestMethod]
//        [DeploymentItem("settings.xml")]
//        [DeploymentItem("Bingo.config.map.xml")]
//        public void SetConfiguration_NoConfigFileForMappingFile_ErrorThrown()
//        {
//            // Arrange
//            var scriptText = String.Format(
//            @"
//                        Import-Module ""{0}ConfigurationInjector.dll""
//                        Set-Configuration -WorkingDirectory ""{0}""
//                    ", GetAssemblyPath());

//            // Act
//            try
//            {
//                // try-catch block, because powershell errors are thrown from the runspace
//                RunScript(scriptText);

//                // Assert
//                Assert.Fail("An exception should be thrown by powershell module!");
//            }
//            catch (Exception exception)
//            {

//                Assert.IsTrue(exception.Message.StartsWith("Config file '"));
//                Assert.IsTrue(exception.Message.EndsWith("' not found!"));
//            }
//        }

//        [TestMethod]
//        [DeploymentItem("bad.settings.xml")]
//        public void SetConfiguration_SettingsFileHasBadRootElement_ErrorThrown()
//        {
//            // Arrange
//            File.Copy(GetAssemblyPath() + "bad.settings.xml", GetAssemblyPath() + "settings.xml");
//            var scriptText = String.Format(
//            @"
//                        Import-Module ""{0}ConfigurationInjector.dll""
//                        Set-Configuration -WorkingDirectory ""{0}""
//                    ", GetAssemblyPath());

//            // Act
//            try
//            {
//                // try-catch block, because powershell errors are thrown from the runspace
//                RunScript(scriptText);

//                // Assert
//                Assert.Fail("An exception should be thrown by powershell module!");
//            }
//            catch (Exception exception)
//            {
//                Assert.AreEqual("'settings.xml' is not in the correct format!", exception.Message);
//            }
//        }

//        [TestMethod]
//        [DeploymentItem("settings.xml")]
//        [DeploymentItem("badRootElement.config.map.xml")]
//        public void SetConfiguration_MapFileHasBadRootElement_ErrorThrown()
//        {
//            var badMapFile = "badRootElement.config.map.xml";

//            TestMapSchema(badMapFile);

//            File.Delete(GetAssemblyPath() + badMapFile);
//        }

//        [TestMethod]
//        [DeploymentItem("settings.xml")]
//        [DeploymentItem("noMapElements.config.map.xml")]
//        public void SetConfiguration_MapFileHasNoMapElements_ErrorThrown()
//        {
//            var badMapFile = "noMapElements.config.map.xml";

//            TestMapSchema(badMapFile);

//            File.Delete(GetAssemblyPath() + badMapFile);
//        }

//        private void TestMapSchema(string fileName)
//        {
//            // Arrange
//            var scriptText = String.Format(
//                @"
//                Import-Module ""{0}ConfigurationInjector.dll""
//                Set-Configuration -WorkingDirectory ""{0}""
//            ", GetAssemblyPath());

//            // Act
//            try
//            {
//                // try-catch block, because powershell errors are thrown from the runspace
//                RunScript(scriptText);

//                // Assert
//                Assert.Fail("An exception should be thrown by powershell module!");
//            }
//            catch (Exception exception)
//            {
//                var expectedMessage = string.Format("'{0}' is not in the correct format!", fileName);
//                Assert.AreEqual(expectedMessage, exception.Message);
//            }
        //        }
        #endregion

        private void AssertIfConfigurationIsAsExpected(string expectedfileName, string resultfileName)
        {
            var expected = new StreamReader(GetAssemblyPath() + expectedfileName).ReadToEnd().Replace(" ", "").Replace(Environment.NewLine, "");
            var result = new StreamReader(GetAssemblyPath() + resultfileName).ReadToEnd().Replace(" ", "").Replace(Environment.NewLine, "");

            Assert.AreEqual(expected, result);
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

