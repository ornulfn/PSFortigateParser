#region Class PSFortigateReport
Class PSFortigateReport : PSFortigateConfigObject {
    #region Properties
    Hidden [System.Array]$PolicyReportTemplate
    Hidden [System.Array]$AddressReportTemplate
    Hidden [System.Array]$AddressGroupReportTemplate
    Hidden [System.Array]$ServiceReportTemplate
    Hidden [System.Array]$ServiceGroupReportTemplate

    #endregion
    #region Constructors
    #region Hidden [void]Constructor()
    Hidden [void] Constructor() {
        # Call parent constructor
        ([PSFortigateConfigObject]$this).Constructor()
        # Setup default templates
        $this.setPolicyReportTemplate()
        $this.setAddressReportTemplate()
        $this.setAddressGroupReportTemplate()
        $this.setServiceReportTemplate()
        $this.setServiceGroupReportTemplate()
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
    #region [void]setPolicyReportTemplate()
    [void]setPolicyReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default policy report template'
        # Columns to report (in listed order)
        #   - merge users and groups to srcaddr
        #   - use LF as separator for multi valued fields (suitable for CSV)
        $this.PolicyReportTemplate = @(
            "vdom", 
            "sequence", 
            "global-label",
            "policyid", 
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
    #region [void]setPolicyReportTemplate($Path)
    [void]setPolicyReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load policy report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.PolicyReportTemplate = $Template
    }

    #endregion
    #region getPolicyReport()
    [PsCustomObject[]]getPolicyReport() {
        return $this.getPolicy() | Sort-Object -Property "vdom","sequence" | Select-Object -Property $this.PolicyReportTemplate
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
    #region [void]setAddressReportTemplate()
    [void]setAddressReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default address report template'
        # Columns to report (in listed order)
        $this.AddressReportTemplate = @(
            "vdom",
            "name",
            "type",
            "associated-interface",
            "subnet",
            "start-ip",
            "end-ip",
            "fqdn",
            "wildcard-fqdn",
            "comment",
            "visibility",
            "allow-routing"
        )
    }

    #endregion
    #region [void]setAddressReportTemplate($Path)
    [void]setAddressReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load address report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.AddressReportTemplate = $Template
    }

    #endregion
    #region getAddressReport()
    [PsCustomObject[]]getAddressReport() {
        return $this.getAddress() | Select-Object -Property $this.AddressReportTemplate
    }

    #endregion
    #region saveAddressReport($Path)
    [void]saveAddressReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getAddressReport() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setAddressGroupReportTemplate()
    [void]setAddressGroupReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default address group report template'
        # Columns to report (in listed order)
        $this.AddressGroupReportTemplate = @(
            "vdom",
            "name",
            @{Name="member"; Expression={ ([array]$_.member) -join [char]10 }},
            "comment",
            "allow-routing"
        )
        
    }

    #endregion
    #region [void]setAddressGroupReportTemplate($Path)
    [void]setAddressGroupReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load address group report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.AddressGroupReportTemplate = $Template
    }

    #endregion
    #region getAddressGroupReport()
    [PsCustomObject[]]getAddressGroupReport() {
        return $this.getAddressGroup() | Select-Object -Property $this.AddressGroupReportTemplate
    }

    #endregion
    #region saveAddressGroupReport($Path)
    [void]saveAddressGroupReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getAddressGroupReport() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setServiceReportTemplate()
    [void]setServiceReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default service report template'
        # Columns to report (in listed order)
        $this.ServiceReportTemplate = @(
            "vdom",
            "name",
            "visibility",
            "proxy",
            "category",
            "protocol",
            "protocol-number",
            @{Name="tcp-portrange"; Expression={ ([array]$_."tcp-portrange") -join [char]10 }},
            @{Name="udp-portrange"; Expression={ ([array]$_."udp-portrange") -join [char]10 }},
            "icmptype",
            "comment"
        )
        
    }

    #endregion
    #region [void]setServiceReportTemplate($Path)
    [void]setServiceReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load service report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.ServiceReportTemplate = $Template
    }

    #endregion
    #region getServiceReport()
    [PsCustomObject[]]getServiceReport() {
        return $this.getService() | Select-Object -Property $this.ServiceReportTemplate
    }

    #endregion
    #region saveServiceReport($Path)
    [void]saveServiceReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getServiceReport() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setServiceGroupReportTemplate()
    [void]setServiceGroupReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default service group report template'
        # Columns to report (in listed order)
        $this.ServiceGroupReportTemplate = @(
            "vdom",
            "name",
            @{Name="member"; Expression={ ([array]$_.member) -join [char]10 }}
        )
        
    }

    #endregion
    #region [void]setServiceGroupReportTemplate($Path)
    [void]setServiceGroupReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load service group report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.ServiceGroupReportTemplate = $Template
    }

    #endregion
    #region getServiceGroupReport()
    [PsCustomObject[]]getServiceGroupReport() {
        return $this.getServiceGroup() | Select-Object -Property $this.ServiceGroupReportTemplate
    }

    #endregion
    #region saveServiceGroupReport($Path)
    [void]saveServiceGroupReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getServiceGroupReport() | `
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