@{
    #Node Specific Data
    AllNodes = @(
        #All servers need the following 
        @{ 
            NodeName = "*" 
            PSDSCAllowPlainTextPassword = $true
        }, 
        #Individual Servers
        @{ 
            NodeName = "TestAF" 
            Role     = "AF Server" 
        }
    ); 
}

