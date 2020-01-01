#region New-PSFortigateConfigObject
function New-PSFortigateConfigObject {
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
        if ($PSCmdlet.ShouldProcess("Create PSFortigateConfigObject instance?")) {
            return (New-Object -Typename "PSFortigateConfigObject" -Argumentlist  $Params)
        }
    }
    catch { throw $_ }

    <#
        .SYNOPSIS
            Create a new PSFortigateConfigObject instance.
        .DESCRIPTION
            The PSFortigateConfigObject instance will create Powershell objects of the Fortigate configuration
        .PARAMETER Params
            Parameters
        .EXAMPLE
            PS C:\>$Config = New-PSFortigateConfigObject -Params @('C:\firewall.conf')
            PS C:\>$Policy = $Config.getPolicy()
        .EXAMPLE
            PS C:\>$Config = New-PSFortigateConfigObject -Params @('C:\firewall.conf', [System.Text.Encoding]::UTF8)
            PS C:\>$Policy = $Config.getPolicy()
        .LINK
            about_PSFortigateConfigObject
    #>
}

#endregion
