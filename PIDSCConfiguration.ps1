
######################   DSC Full Environment Configuration  ######################
Configuration PIDSCConfiguration
{
    param
    (
        [String]$nodeName = 'localhost',
        [PSCredential]$Credential, #(An Administrator Cred).This is passed in via a Get-Credential Hash Table, at a runtime prompt
        [PSCredential]$AFCredential #(AF Server Service Account).This is passed in via a Get-Credential Hash Table, at a runtime prompt
    )
        
   Import-DscResource -Module xNetworking   
   Import-DscResource -Module xPSDesiredStateConfiguration
    
    #Setup for all machines assuming you split it into PI Data archive, AF Server etc further down.
    #Windows features. These cannot be duplicated in the Node by Roles section.
    Node $AllNodes.nodename
    { 
        ######################   Windows Roles and Features  ######################
        # Just make sure the .NET framework is installed.
        # Install .NET Framework 3.5
        WindowsFeature NETFrameworkFeatures 
        {
            Ensure = "Present"
            Name = "NET-Framework-Core"
            IncludeAllSubFeature = $true
        }  

        # Install .NET Framework 4.5
        WindowsFeature NETFramework45Features
        {
            Ensure = "Present"
            Name = "NET-Framework-45-Features"
            IncludeAllSubFeature = $true
        }        
    } 
         
    #Setup only  if the role is "AFServer" 
    Node $AllNodes.Where{$_.Role -eq "AF Server"}.NodeName
    {    
        ######################   Firewall Rules  ######################
        #Firewall TCP Rules, these can be more restricted based on IP, other rules etc.
        xFirewall Firewall 
        { 
            Name             = "PIAFRules" 
            DisplayName      = "PI AF Server Access" 
            DisplayGroup     = "PI AF Firewall Rule Group" 
            Ensure           = "Present" 
            Access           = "Allow" 
            State            = "Enabled" 
            Profile          = ("Domain", "Private", "Public") 
            Direction        = "InBound" 
            LocalPort        = ("5457", "5459") 
            Protocol         = "TCP" 
            Description      = "Allow Remote Access to the AF Server"   
        } 

        ######################   Move Install Kits  ######################
        #Move installkits from Fileshare \\FileShare\OSISoft_InstallKits for now to machines you are installing on 
        #Move Sysinternals Suite over to Server
        #Note DSC Runs as SYSTEM so you need to add the Machine$ to the souce folder security tab for it to have access
        File DirectoryCopy
        {
            Ensure = "Present"  
            Type = "Directory"
            Recurse = $true 
            SourcePath = "\\XXXXXXXXX\OSISoft_InstallKits" #These are coming from another computer domain, but a network fileshare would work as well
            DestinationPath = "C:\OSISoft_InstallKits"  
            Force = $true  
        }

        ######################   Install Software  ######################
        #Note that the machine already has a SQL Express installation on it.
        #It's possible to add this to the DSC script via the xSqlPs resource, omitted here for clarity
        #The Unzipped clients are also present, with PowerShell you can unzip them in the script as well
        #Install PI AF Server 2014 R2, AF Client
        #Modified Silent.Ini file to include .\SQLExpress and ADDLOCAL=ALL for the AFServer_x64.msi
        xPackage PIAFServer
        {
            Ensure = "Present" 
            Path  = "C:\OSISoft_InstallKits\PI-AF-Server_2014-R2_\AFServer_2.6.1.6238\setup.exe" #Already Unzipped 
            Arguments = "-f C:\OSISoft_InstallKits\PI-AF-Server_2014-R2_\AFServer_2.6.1.6238\silent.ini"
            Name =  "PI AF Server (x64) 2014 R2"
            ProductId = "" 
            DependsOn = @('[WindowsFeature]NETFrameworkFeatures','[WindowsFeature]NETFramework45Features') #Ex: Make sure .Net 3.5, 4.5 is installed first
            RunAsCredential = $Credential
            Credential = $Credential
        } 

        #Install PI AF Client 
        xPackage PIAFClient
        {
            Ensure = "Present" 
            Path  = "C:\OSISoft_InstallKits\PI-AF-Client_2014-R2_\AFClient_2.6.1.6238\setup.exe" #Already Unzipped 
            Arguments = "-f C:\OSISoft_InstallKits\PI-AF-Client_2014-R2_\AFClient_2.6.1.6238\silent.ini"
            Name =  "PI AF Client (x64) 2014 R2"
            ProductId = "" 
            DependsOn = '[xPackage]PIAFServer'
            RunAsCredential = $Credential
            Credential = $Credential
        } 
        
        ######################   Set Service Accounts  ######################
        #Set Service PI AF SERVER to domain\afserviceaccount
        #Service to change credentials. xService DSC resource to create a new service.
        Service PIAFServerService
        {
            Name = 'AFService'
            DisplayName = 'PI AF Server 2.x Application Service'
            Ensure = 'Present'
            StartupType = 'Automatic'
            DependsOn = '[xPackage]PIAFServer'
            State = 'Running'
            Credential = $AFCredential
        }

     }
    
}


