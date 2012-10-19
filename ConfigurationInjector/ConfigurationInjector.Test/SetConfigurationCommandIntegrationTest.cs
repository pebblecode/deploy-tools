using System;
using System.IO;
using System.Management.Automation.Runspaces;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace ConfigurationInjector.Test
{
    /// <summary>
    /// Contains integration test for the Set-Configuration powershell command
    /// </summary> 
    [TestClass]
    public class SetConfigurationCommandIntegrationTest
    {
        [TestMethod]
        public void SetConfiguration_TryInjectionLocalFiles_FilesAreUpdated()
        {
            // Arrange
            var scriptText = String.Format(
            @"
                cd {0}
                Import-Module ./ConfigurationInjector.dll 
                Set-Configuration -WorkingDirectory {0}
            ", GetAssemblyPath());
            
            // Act
            try
            {
                // try-catch block, because powershell errors are thrown from the runspace
                RunScript(scriptText);
            } 
            catch(Exception exception)
            {
                Assert.Fail(exception.Message);
            }
            

            // Assert
            AssertIfConfigurationIsAsExpected();            
        }

        private void AssertIfConfigurationIsAsExpected()
        {
            var expected = new StreamReader(GetAssemblyPath() + "expectedtest.config").ReadToEnd();
            var result = new StreamReader(GetAssemblyPath() + "test.config").ReadToEnd();
           
            Assert.AreEqual(expected, result);
        }

        private string GetAssemblyPath()
        {
            var codeBase = System.Reflection.Assembly.GetExecutingAssembly().GetName().CodeBase;
            var directory = Path.GetDirectoryName(codeBase);
            return directory.Replace("file:\\", String.Empty) + "\\";
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
