#region New-PSFortigateReport
function New-PSFortigateReport {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
    	[Parameter(
	    	Mandatory = $False,
		    ValueFromPipeline = $False,
	    	HelpMessage="Parameters")]
            [System.Array]$Params
    )
    try {
        if ($PSCmdlet.ShouldProcess("Create PSFortigateReport instance?")) {
            return (New-Object -Typename "PSFortigateReport" -Argumentlist  $Params)
        }
    }
    catch { throw $_ }
    <#
        .SYNOPSIS
            Create a new PSFortigateReport instance.
        .DESCRIPTION
            The PSFortigateReport instance will create CSV reports of the Fortigate configuration
        .PARAMETER Params
            Parameters
        .EXAMPLE
            PS C:\>$Config = New-PSFortigateReport -Params @('C:\firewall.conf')
            PS C:\>$Config.savePolicyReport('C:\firewall-policy.csv')
            PS C:\>$Config.saveAddressReport('C:\firewall-address.csv')
            PS C:\>$Config.saveAddressGroupReport('C:\firewall-addressgroup.csv')
            PS C:\>$Config.saveServiceReport('C:\firewall-service.csv')
            PS C:\>$Config.saveServiceGroupReport('C:\firewall-servicegroup.csv')
        .EXAMPLE
            PS C:\>$Config = New-PSFortigateReport -Params @('C:\firewall.conf', [System.Text.Encoding]::UTF8)
            PS C:\>$Config.savePolicyReport('C:\firewall-policy.csv')
            PS C:\>$Config.saveAddressReport('C:\firewall-address.csv')
            PS C:\>$Config.saveAddressGroupReport('C:\firewall-addressgroup.csv')
            PS C:\>$Config.saveServiceReport('C:\firewall-service.csv')
            PS C:\>$Config.saveServiceGroupReport('C:\firewall-servicegroup.csv')
        .LINK
            about_PSFortigateReport
    #>
}

#endregion
