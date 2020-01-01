#region New-PSFortigateConfig
function New-PSFortigateConfig {
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
         if ($PSCmdlet.ShouldProcess("Create PSFortigateConfig instance?")) {
            return (New-Object -Typename "PSFortigateConfig" -Argumentlist  $Params)
        }
    }
    catch { throw $_ }

    <#
        .SYNOPSIS
            Create a new PSFortigateConfig instance.
        .DESCRIPTION
            The PSFortigateConfigObject instance will parse the Fortigate configuration into a hash table
        .PARAMETER Params
            Parameters
        .EXAMPLE
            PS C:\>$Config = New-PSFortigateConfig -Params @('C:\firewall.conf')
            PS C:\>$Config.Config['global']['system global']['hostname']
        .EXAMPLE
            PS C:\>$Config = New-PSFortigateParser -Params @('C:\firewall.conf', [System.Text.Encoding]::UTF8)
            PS C:\>$Config.Config['global']['system global']['hostname']
        .LINK
            about_PSFortigateConfig
    #>
}

#endregion
