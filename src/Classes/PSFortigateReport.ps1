#region Class PSFortigateReport
Class PSFortigateReport : PSFortigateConfigObject {
    #region Properties
    Hidden [System.Array]$PolicyReportTemplate
    Hidden [System.Array]$AddressReportTemplate
    Hidden [System.Array]$AddressGroupReportTemplate
    Hidden [System.Array]$ServiceReportTemplate
    Hidden [System.Array]$ServiceGroupReportTemplate
    Hidden [System.Array]$LocalUserReportTemplate
    Hidden [System.Array]$FortitokenReportTemplate
    Hidden [System.Array]$UserGroupReportTemplate

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
        $this.setLocalUserReportTemplate()
        $this.setFortitokenReportTemplate()
        $this.setUserGroupReportTemplate()
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
    #region [void]setLocalUserReportTemplate()
    [void]setLocalUserReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default local user report template'
        # Columns to report (in listed order)
        $this.LocalUserReportTemplate = @(
            "vdom",
            "status",
            "name",
            @{Name="email"; Expression={ $_."email-to" }},
            @{Name="phone"; Expression={ $_."sms-phone" }},
            "fortitoken"
        )
        
    }

    #endregion
    #region [void]setLocalUserReportTemplate($Path)
    [void]setLocalUserReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load local user report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.LocalUserReportTemplate = $Template
    }

    #endregion
    #region getLocalUserReport()
    [PsCustomObject[]]getLocalUserReport() {
        return $this.getLocalUser() | Select-Object -Property $this.LocalUserReportTemplate
    }

    #endregion
    #region saveLocalUserReport($Path)
    [void]saveLocalUserReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getLocalUserReport() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setFortitokenReportTemplate()
    [void]setFortitokenReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default fortitoken report template'
        # Columns to report (in listed order)
        $this.FortitokenReportTemplate = @(
            "vdom",
            @{Name="fortitoken"; Expression={ $_."name" }},
            "comments",
            "activation-code",
            @{Name="activation-expire"; Expression={ if($_."activation-expire".Length -gt 0) { [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_."activation-expire")) }}}
        )
        
    }

    #endregion
    #region [void]setFortitokenReportTemplate($Path)
    [void]setFortitokenReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load fortitoken report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.FortitokenReportTemplate = $Template
    }

    #endregion
    #region getFortitokenReport()
    [PsCustomObject[]]getFortitokenReport() {
        return $this.getFortitoken() | Select-Object -Property $this.FortitokenReportTemplate
    }

    #endregion
    #region saveFortitokenReport($Path)
    [void]saveFortitokenReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getFortitokenReport() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setUserGroupReportTemplate()
    [void]setUserGroupReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default user group report template'
        # Columns to report (in listed order)
        $this.UserGroupReportTemplate = @(
            "vdom",
            "name",
            @{Name="member"; Expression={ ([array]$_.member) -join [char]10 }}
        )
    }

    #endregion
    #region [void]setUserGroupReportTemplate($Path)
    [void]setUserGroupReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load user group report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.UserGroupReportTemplate = $Template
    }

    #endregion
    #region getUserGroupReport()
    [PsCustomObject[]]getUserGroupReport() {
        return $this.getUserGroup() | Select-Object -Property $this.UserGroupReportTemplate
    }

    #endregion
    #region saveUserGroupReport($Path)
    [void]saveUserGroupReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getUserGroupReport() | `
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