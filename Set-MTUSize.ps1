 <#
.SYNOPSIS
    Set MTU packet size for specified computer(s).

.DESCRIPTION
    Set MTU packet size for specified computer(s).

.PARAMETER Computername
    Select local or remote computer by hostname or IP address.

.PARAMETER NetworkAdapters
    Select network interface card (NIC) by name.
    Default='Local Area Connection'

.PARAMETER MTUSize
    Set maximum MTU size.
    Default='1500'

.PARAMETER Store
    Set configuration storage interval. 
    Default='Persistent'

.NOTES
    Author: JBear
    Date: 10/28/2017
#>

param(

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Computername,

    [Parameter(ValueFromPipeline=$true,HelpMessage="NIC Name")]
    [ValidateNotNullOrEmpty()]
    [String[]]$NetworkAdapters='Local Area Connection',   

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [Int]$MTUSize='1500',

    [Parameter(ValueFromPipeline=$true, HelpMessage="Active or Persistent")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Persistent", "Active")]
    [String]$Store='Persistent'
)
    
$i=0
$j=0

function Set-MTUValue { 

    foreach($Computer in $Computername) {
                
        if(!([String]::IsNullOrWhiteSpace($Computer))) {

            Write-Progress -Activity "Setting MTU to $($MTUSize)..." -Status ("Percent Complete:" + "{0:N0}" -f ((($i++) / $Computername.count) * 100) + "%") -CurrentOperation "Processing $($Computer)..." -PercentComplete ((($j++) / $Computername.count) * 100)

            if(Test-Connection -Quiet -Count 1 -Computer $Computer) {
                        
                Invoke-Command -ComputerName $Computer { param($NetworkAdapters, $MTUSize, $Store)

                    foreach($NIC in $NetworkAdapters) {

                        $Before = netsh Interface IPv4 Show SubInterface
                        netsh Interface IPv4 Set SubInterface $($NIC) MTU=$MTUSize Store=$Store | Out-Null
                        $After = netsh Interface IPv4 Show SubInterface
                            
                        "`n" + $env:COMPUTERNAME
                        $Before
                        $After + "`n"                      
                    }
                } -ArgumentList $NetworkAdapters, $MTUSize, $Store -AsJob -JobName "Set MTU: $($MTUSize)."
            }

            else {
            
                Write-Host -ForegroundColor Yellow "[Notice] Unable to PING - $($Computer)"
            }
        }

        else {
        
            Write-Host -ForegroundColor Red "[Notice] Value is null."
        }
    }
}

#Call main function
Set-MTUValue | Receive-Job -Wait 
