#$Credential uses the Administrator account first in order to install files
#$AFServiceAccount uses the Domain\AFServiceAccount to run the AF Server 
$configurationArguments = @{ Credential = Get-Credential ; AFCredential = Get-Credential }

#Enable DSC on the VM and Set the configuration
$context = New-AzureStorageContext -StorageAccountName XXXXXXXXX -StorageAccountKey XXXXXXXXX

#The Path to my Configuration DSC Script, published to the Storage Context
Publish-AzureVMDscConfiguration -ConfigurationPath "C:\Program Files\WindowsPowerShell\scripts\PIDSCConfiguration.ps1" -StorageContext $context -Force

$vm = Get-AzureVM -Name "TestAF" -ServiceName "XXXXXXXXX" 

Set-AzureVMDscExtension -VM $vm -ConfigurationArchive "PIDSCConfiguration.ps1.zip" -ConfigurationName "PIDSCConfiguration" -ConfigurationDataPath "C:\Program Files\WindowsPowerShell\scripts\PIDSCEnvironmentalData.psd1" -StorageContext $context -ConfigurationArgument $configurationArguments | Update-AzureVM

#To Check the Status of your DSC Configuration
#Get-AzureVMDscExtension -VM $vm
#Get-AzureVMDscExtensionStatus -ServiceName XXXXXXXXX -Name XXXXXXXX
#(Get-AzureVMDscExtensionStatus -ServiceName XXXXXXXX -Name XXXXXXXX).Dscconfigurationlog

