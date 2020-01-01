#region Class PSFortigateReport
Class PSFortigateReport : PSFortigateConfigObject {
    #region Properties
    Hidden [System.Array]$PolicyReportTemplate

    #endregion
    #region Constructors
    #region Hidden [void]Constructor()
    Hidden [void] Constructor() {
        # Call parent constructor
        ([PSFortigateConfigObject]$this).Constructor()
        # Setup default templates
        $this.setPolicyReportTemplate()
    }

    #endregion
    #region PSFortigateConfig($Path)
    PSFortigateReport(
        [System.String]$Path
    ) : base($Path) {
        $this.Path = $Path
    }

    #endregion
    #region PSFortigateConfigObject($Path, $Encoding)
    PSFortigateReport(
        [System.String]$Path,
        [System.Text.Encoding]$Encoding
    ) : base($Path, $Encoding) {
        $this.Path = $Path
        $this.Encoding = $Encoding
    }

    #endregion
    #endregion
    #region setPolicyReportTemplate()
    Hidden [void]setPolicyReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default policy report template'
        # Columns to report (in listed order)
        #   - merge users and groups to srcaddr
        #   - use LF as separator for multi valued fields (suitable for CSV)
        $this.PolicyReportTemplate = @(
            "vdom", 
            "global-label",
            "sequence", 
            "status", 
            "name", 
            @{Name="srcintf"; Expression={ ([array]$_.srcintf) -join [char]10 }},
            @{Name="srcaddr"; Expression={
                $out = $_.srcaddr; 
                if ($_.users.length -gt 0) { $out = [array]$out + $_.users };
                if ($_.groups.length -gt 0) { $out = [array]$out + $_.groups };
                $out -join [char]10 }},
            @{Name="dstintf"; Expression={ ([array]$_.dstintf) -join [char]10 }},
            @{Name="dstaddr"; Expression={ ([array]$_.dstaddr) -join [char]10 }},
            "nat", 
            @{Name="service"; Expression={ ([array]$_.service) -join [char]10 }},
            "action", 
            "logtraffic", 
            "schedule",
            "comments"
        )
    }

    #endregion
    #region getPolicyReport()
    [PsCustomObject[]]getPolicyReport() {
        return $this.getPolicy() | Select-Object -Property $this.PolicyReportTemplate
    }

    #endregion
    #region savePolicyReport($Path)
    [void]savePolicyReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getPolicyReport() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
}

#endregion