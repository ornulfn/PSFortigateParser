#region Class PSFortigateReport
Class PSFortigateReport : PSFortigateConfigObject {
    #region Properties
    Hidden [System.Array]$PolicyReportTemplate
    Hidden [System.Array]$ProxyPolicyReportTemplate
    Hidden [System.Array]$AddressReportTemplate
    Hidden [System.Array]$AddressGroupReportTemplate
    Hidden [System.Array]$ServiceReportTemplate
    Hidden [System.Array]$ServiceGroupReportTemplate
    Hidden [System.Array]$LocalUserReportTemplate
    Hidden [System.Array]$FortitokenReportTemplate
    Hidden [System.Array]$UserGroupReportTemplate
    Hidden [System.Array]$InterfaceReportTemplate
    Hidden [System.Array]$IPsecPhase1ReportTemplate
    Hidden [System.Array]$IPsecPhase2ReportTemplate
    Hidden [System.Array]$SystemZoneReportTemplate
    Hidden [System.Array]$RouterStaticReportTemplate

    #endregion
    #region Constructors
    #region Hidden [void]Constructor()
    Hidden [void] Constructor() {
        # Call parent constructor
        ([PSFortigateConfigObject]$this).Constructor()
        # Setup default templates
        $this.setPolicyReportTemplate()
        $this.setProxyPolicyReportTemplate()
        $this.setAddressReportTemplate()
        $this.setAddressGroupReportTemplate()
        $this.setServiceReportTemplate()
        $this.setServiceGroupReportTemplate()
        $this.setLocalUserReportTemplate()
        $this.setFortitokenReportTemplate()
        $this.setUserGroupReportTemplate()
        $this.setInterfaceReportTemplate()
        $this.setIPsecPhase1ReportTemplate()
        $this.setIPsecPhase2ReportTemplate()
        $this.setSystemZoneReportTemplate()
        $this.setRouterStaticReportTemplate()
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
            @{Name="logtraffic"; Expression={
                $out = $_."logtraffic"
                if ($null -ne $_."logtraffic-start" -and $_."logtraffic-start".ToLower() -eq "enable") { $out = [array]$out + "at session start" };
                if ($null -ne $_."capture-packet" -and $_."capture-packet".ToLower() -eq "enable") { $out = [array]$out + "capture packet" };
                $out -join [char]10 }},
            @{Name="securityprofile"; Expression={
                $out = $null
                if ($null -ne $_."av-profile" -and $_."av-profile".length -gt 0) { $out = [array]$out + ("AV: {0}" -f $_."av-profile") };
                if ($null -ne $_."webfilter-profile" -and $_."webfilter-profile".length -gt 0) { $out = [array]$out + ("Web: {0}" -f $_."webfilter-profile") };
                if ($null -ne $_."dnsfilter-profile" -and $_."dnsfilter-profile".length -gt 0) { $out = [array]$out + ("DNS: {0}" -f $_."dnsfilter-profile") };
                if ($null -ne $_."spamfilter-profile" -and $_."spamfilter-profile".length -gt 0) { $out = [array]$out + ("Spam: {0}" -f $_."spamfilter-profile") };
                if ($null -ne $_."dlp-sensor" -and $_."dlp-sensor".length -gt 0) { $out = [array]$out + ("DLP: {0}" -f $_."dlp-sensor") };
                if ($null -ne $_."ips-sensor" -and $_."ips-sensor".length -gt 0) { $out = [array]$out + ("IPS: {0}" -f $_."ips-sensor") };
                if ($null -ne $_."application-list" -and $_."application-list".length -gt 0) { $out = [array]$out + ("App: {0}" -f $_."application-list") };
                if ($null -ne $_."voip-profile" -and $_."voip-profile".length -gt 0) { $out = [array]$out + ("VoIP: {0}" -f $_."voip-profile") };
                if ($null -ne $_."icap-profile" -and $_."icap-profile".length -gt 0) { $out = [array]$out + ("ICAP: {0}" -f $_."icap-profile") };
                if ($null -ne $_."waf-profile" -and $_."waf-profile".length -gt 0) { $out = [array]$out + ("WAF: {0}" -f $_."waf-profile") };
                if ($null -ne $_."profile-protocol-options" -and $_."profile-protocol-options".length -gt 0) { $out = [array]$out + ("Protocol: {0}" -f $_."profile-protocol-options") };
                if ($null -ne $_."ssl-ssh-profile" -and $_."ssl-ssh-profile".length -gt 0) { $out = [array]$out + ("SSL/SSH: {0}" -f $_."ssl-ssh-profile") };
                $out -join [char]10 }},
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
    #region [void]setInterfaceReportTemplate()
    [void]setInterfaceReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default interface report template'
        # Columns to report (in listed order)
        $this.InterfaceReportTemplate = @(
            "vdom",
            "name",
            "status",
            "type",
            "interface",
            "ip",
            @{Name="webproxy"; Expression={ $_."explicit-web-proxy" }},
            "description"
        )
    }

    #endregion
    #region [void]setInterfaceReportTemplate($Path)
    [void]setInterfaceReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load interface report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.InterfaceReportTemplate = $Template
    }

    #endregion
    #region getInterfaceReport()
    [PsCustomObject[]]getInterfaceReport() {
        return $this.getInterface() | Select-Object -Property $this.InterfaceReportTemplate
    }

    #endregion
    #region saveInterfaceReport($Path)
    [void]saveInterfaceReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getInterfaceReport() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setInterfaceReportTemplate()
    [void]setIPsecPhase1ReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default ipsec phase1 report template'
        # Columns to report (in listed order)
        $this.IPsecPhase1ReportTemplate = @(
            "vdom",
            "name",
            "interface",
            "remote-gw",
            "nattraversal",
            "ike-version",
            "keylife",
            "proposal",
            "dpd",
            "dhgrp",
            "comments"
        )
    }

    #endregion
    #region [void]setIPsecPhase1ReportTemplate($Path)
    [void]setIPsecPhase1ReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load ipsec phase1 report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.IPsecPhase1ReportTemplate = $Template
    }

    #endregion
    #region getIPsecPhase1Report()
    [PsCustomObject[]]getIPsecPhase1Report() {
        return $this.getIPsecPhase1() | Select-Object -Property $this.IPsecPhase1ReportTemplate
    }

    #endregion
    #region saveIPsecPhase1Report($Path)
    [void]saveIPsecPhase1Report(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getIPsecPhase1Report() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setIPsecPhase2ReportTemplate()
    [void]setIPsecPhase2ReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default ipsec phase2 report template'
        # Columns to report (in listed order)
        $this.IPsecPhase2ReportTemplate = @(
            "vdom",
            "name",
            "phase1name",
            "keylifeseconds",
            "proposal",
            @{Name="dhgrp"; Expression={
                if ($_."dhgrp".length -gt 0) { $out = [array]$out + $_."dhgrp" };
                if ($_."pfs".length -gt 0) { $out = [array]$out + ("pfs {0}" -f $_."pfs") };
                $out -join [char]10 }},
            @{Name="src"; Expression={
                if ($_."src-name".length -gt 0) { $out = [array]$out + $_."src-name" };
                if ($_."src-subnet".length -gt 0) { $out = [array]$out + $_."src-subnet" };
                $out -join [char]10 }},
            @{Name="dst"; Expression={
                if ($_."dst-name".length -gt 0) { $out = [array]$out + $_."dst-name" };
                if ($_."dst-subnet".length -gt 0) { $out = [array]$out + $_."dst-subnet" };
                $out -join [char]10 }},
            "comments"
        )
    }

    #endregion
    #region [void]setIPsecPhase2ReportTemplate($Path)
    [void]setIPsecPhase2ReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load ipsec phase2 report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.IPsecPhase2ReportTemplate = $Template
    }

    #endregion
    #region getIPsecPhase2Report()
    [PsCustomObject[]]getIPsecPhase2Report() {
        return $this.getIPsecPhase2() | Select-Object -Property $this.IPsecPhase2ReportTemplate
    }

    #endregion
    #region saveIPsecPhase2Report($Path)
    [void]saveIPsecPhase2Report(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getIPsecPhase2Report() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setSystemZoneReportTemplate()
    [void]setSystemZoneReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default system zone report template'
        # Columns to report (in listed order)
        $this.SystemZoneReportTemplate = @(
            "vdom",
            "name",
            "intrazone",
            @{Name="interface"; Expression={ ([array]$_.interface) -join [char]10 }}
        )
        
    }

    #endregion
    #region [void]setSystemZoneReportTemplate($Path)
    [void]setSystemZoneReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load system zone report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.SystemZoneReportTemplate = $Template
    }

    #endregion
    #region getSystemZoneReport()
    [PsCustomObject[]]getSystemZoneReport() {
        return $this.getSystemZone() | Select-Object -Property $this.SystemZoneReportTemplate
    }

    #endregion
    #region saveSystemZoneReport($Path)
    [void]saveSystemZoneReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getSystemZoneReport() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setRouterStaticReportTemplate()
    [void]setRouterStaticReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default router static report template'
        # Columns to report (in listed order)
        $this.RouterStaticReportTemplate = @(
            "vdom",
            "name",
            "status",
            @{Name="dst"; Expression={
                if ($_."dst".length -gt 0) { $out = [array]$out + $_."dst" };
                if ($_."dstaddr".length -gt 0) { $out = [array]$out + $_."dstaddr" };
                $out -join [char]10 }},
            "gateway",
            "device",
            "blackhole",
            "comment"
        )
    }

    #endregion
    #region [void]setRouterStaticReportTemplate($Path)
    [void]setRouterStaticReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load router static report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.RouterStaticReportTemplate = $Template
    }

    #endregion
    #region getRouterStaticReport()
    [PsCustomObject[]]getRouterStaticReport() {
        return $this.getRouterStatic() | Select-Object -Property $this.RouterStaticReportTemplate
    }

    #endregion
    #region saveRouterStaticReport($Path)
    [void]saveRouterStaticReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getRouterStaticReport() | `
            ConvertTo-Csv -NoTypeInformation -Delimiter (Get-Culture).TextInfo.ListSeparator | `
            ForEach-Object { $StreamWriter.WriteLine($_) }
        $StreamWriter.Close()
        $StreamWriter.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion

    #region [void]setProxyPolicyReportTemplate()
    [void]setProxyPolicyReportTemplate() {
        Write-Debug 'PSFortigateReport: Set default policy report template'
        # Columns to report (in listed order)
        #   - merge users and groups to srcaddr
        #   - use LF as separator for multi valued fields (suitable for CSV)
        $this.ProxyPolicyReportTemplate = @(
            "vdom", 
            "sequence", 
            "policyid", 
            "status", 
            @{Name="srcaddr"; Expression={
                $out = $_.srcaddr; 
                if ($_.users.length -gt 0) { $out = [array]$out + $_.users };
                if ($_.groups.length -gt 0) { $out = [array]$out + $_.groups };
                $out -join [char]10 }},
            @{Name="dstintf"; Expression={ ([array]$_.dstintf) -join [char]10 }},
            @{Name="dstaddr"; Expression={ ([array]$_.dstaddr) -join [char]10 }},
            @{Name="service"; Expression={
                $out = $_."service"
                if ($null -ne $_."internet-service-id" -and $_."internet-service-id".length -gt 0) { $out = [array]$out + ([array]$_."internet-service-id" | ForEach-Object { "Inet ID: {0}" -f $_ }) -join [char]10 };
                $out -join [char]10 }},
            "action", 
            @{Name="logtraffic"; Expression={
                $out = $_."logtraffic"
                if ($null -ne $_."logtraffic-start" -and $_."logtraffic-start".ToLower() -eq "enable") { $out = [array]$out + "at session start" };
                if ($null -ne $_."capture-packet" -and $_."capture-packet".ToLower() -eq "enable") { $out = [array]$out + "capture packet" };
                $out -join [char]10 }},
            "proxy",
            "schedule",
            "comments"
        )
    }

    #endregion
    #region [void]setProxyPolicyReportTemplate($Path)
    [void]setProxyPolicyReportTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateReport: Load policy report template from {0}' -f $Path)
        $Template = Invoke-Command -ScriptBlock ([scriptblock]::Create(($this.ReadTextFile($Path))))
        $this.ProxyPolicyReportTemplate = $Template
    }

    #endregion
    #region getProxyPolicyReport()
    [PsCustomObject[]]getProxyPolicyReport() {
        return $this.getProxyPolicy() | Sort-Object -Property "vdom","sequence" | Select-Object -Property $this.ProxyPolicyReportTemplate
    }

    #endregion
    #region saveProxyPolicyReport($Path)
    [void]saveProxyPolicyReport(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::CreateNew), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::Write)
        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, $this.Encoding
        $this.getProxyPolicyReport() | `
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