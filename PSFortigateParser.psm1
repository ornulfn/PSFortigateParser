#Generated at 2020-01-03 16:19 by Ørnulf Nielsen
#region Class PSFortigateConfig : System.IDisposable
Class PSFortigateConfig : System.IDisposable {
    #region Properties
    Hidden [System.Boolean]$Disposing = $false
    [System.String]$Path
    [System.Text.Encoding]$Encoding = [System.Text.Encoding]::Default
    Hidden [System.IO.FileStream]$FileStream
    Hidden [System.IO.StreamReader]$StreamReader
    Hidden [System.Boolean]$BreakTopLevel = $false
    Hidden [System.Boolean]$inPolicySection = $false
    Hidden [System.Boolean]$inServiceSection = $false
    Hidden [System.Int32]$PolicySequence

    [System.Collections.Hashtable]$Config

    #endregion
    #region Constructors
    #region Hidden [void]Constructor()
    [void] Constructor() {
        $this.FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $this.Path, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
        $this.StreamReader = New-Object -TypeName System.IO.StreamReader -ArgumentList $this.FileStream, $this.Encoding
        $this.Config = New-Object System.Collections.Hashtable
        $this.ReadConfig()
        $this.StreamReader.Close()
        $this.FileStream.Close()
    }

    #endregion
    #region PSFortigateConfig($Path)
    PSFortigateConfig(
        [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfig: Read {0}' -f $Path)
        $this.Path = $Path
        $this.Constructor()
    }

    #endregion
    #region PSFortigateConfig($Path, $Encoding)
    PSFortigateConfig(
        [System.String]$Path,
        [System.Text.Encoding]$Encoding
    ) {
        Write-Debug ('PSFortigateConfig: Read {0} using {1}' -f $Path, ($Encoding).EncodingName)
        $this.Path = $Path
        $this.Encoding = $Encoding
        $this.Constructor()
    }

    #endregion
    #endregion
    #region Destructors
    #region Dispose()
    [void] Dispose() { 
        $this.Disposing = $true
        $this.Dispose($true)

        [System.GC]::SuppressFinalize($this)
    }

    #endregion
    #region Dispose($Disposing)
    [void] Dispose(
        [System.Boolean]$Disposing
    ) { 
        if($Disposing) {
            $this.StreamReader.Dispose()
            $this.FileStream.Dispose()
        }
    }

    #endregion
    #endregion
    #region ReadConfig
    Hidden ReadConfig() {
        while ($this.StreamReader.Peek() -ge 0) {
            $this.BreakTopLevel = $false
            $sLine = $this.StreamReader.ReadLine()

            if ([Environment]::UserInteractive) {
                Write-Progress `
                    -Activity ('Parsing {0}' -f ($this.StreamReader.BaseStream.Name | Split-Path -Leaf)) `
                    -PercentComplete ([int32]($this.StreamReader.BaseStream.Position * 100 / $this.StreamReader.BaseStream.Length))
            }
            if ($sLine -match "^\s*config\s+(?<section>.*)\s*$") {
                $ConfigSection = $this.ReadConfigSection($Matches.section, 'end')
                # Merge sections which occur multiple times on top level in config
                if ($this.Config.ContainsKey($Matches.section)) {
                    # vdom
                    if ($Matches.section -eq 'vdom') {
                        foreach ($h in $ConfigSection.GetEnumerator()) {
                            Write-Debug ('PSFortigateConfig: Found config section vdom {0}' -f $h.Name)
                            $this.Config[$Matches.section][$h.Name] = $h.Value
                        }
                    }
                } else {
                    Write-Debug ('PSFortigateConfig: Found config section {0}' -f $Matches.section)
                    $this.Config[$Matches.section] = $ConfigSection
                }
                continue
            }
        }
    }
    #endregion
    #region ReadConfigSection
    Hidden [System.Collections.Hashtable]ReadConfigSection(
            [System.String]$CurrentSection,
            [System.String]$EndMarker
        ) {
        $Section = New-Object System.Collections.Hashtable
        while ($this.StreamReader.Peek() -ge 0) {
            # Special handling for vdom - end without next
            if ($this.BreakTopLevel) {
                Write-Debug 'PSFortigateConfig: end without next'
                break
            }

            $sLine = $this.StreamReader.ReadLine()
            # Recurse config and edit statements
            if ($sLine -match "^\s*(?<type>config|edit)\s+(?<section>.*)\s*$") {
                if ($Matches.type -eq 'config') {
                    Write-Debug ('PSFortigateConfig: Found config section {0}' -f $Matches.section)
                    if ($Matches.section -eq "firewall policy") {
                        $this.inPolicySection = $true
                        $this.PolicySequence = 0
                    } elseif ($Matches.section -eq "firewall service custom") {
                        $this.inServiceSection = $true
                    }
                    $Section[$Matches.section] = $this.ReadConfigSection($Matches.section, 'end')
                } else {
                    Write-Debug ('PSFortigateConfig: Found config sub section {0}' -f $Matches.section)
                    if ($this.inPolicySection) {
                        $this.PolicySequence++
                    }
                    $Section[$Matches.section -replace "`"",""] = $this.ReadConfigSection($Matches.section, 'next')
                }
                continue
            }
            # Break on end and next statements
            if ($sLine -match ("^\s*(?<EndMarker>next|end)\s*$")) {
                # Special handling for vdom - end without next
                if ($Matches.EndMarker -eq "end" -and $this.inPolicySection) {
                    $this.inPolicySection = $false
                } elseif ($Matches.EndMarker -eq "end" -and $this.inServiceSection) {
                    $this.inServiceSection = $false
                }
                if ($Matches.EndMarker -eq "end" -and $EndMarker -eq "next") {
                    $this.BreakTopLevel = $true
                }
                break
            }
            # Section property
            if ($sLine -match "^(\s*)set\s+(?<Key>[^\s]+)\s+(?<Value>.+)\s*$") {
                $PropertyKey = $Matches.Key -replace "`"",""

                # Inject sequence number for firewall policy
                if ($PropertyKey -eq "name" -and $this.inPolicySection) {
                    $Section['sequence'] = $this.PolicySequence
                }

                # Remove double quotes - use array if multi-valued
                if ($this.inServiceSection -and $PropertyKey -like "*-portrange") {
                    $PropertyValue = $Matches.Value -split "\s+"
                    if ($PropertyValue.Count -eq 1) {
                        $PropertyValue = $PropertyValue -as [System.String]
                    }
                } else {
                    $PropertyValue = $Matches.Value -split "`"\s+`""
                    if ($PropertyValue.Count -gt 1) {
                        $PropertyValue[0] = $PropertyValue[0] -replace "^`"",""
                        $PropertyValue[-1] = $PropertyValue[-1] -replace "`"\s*$",""
                    } else {
                        $PropertyValue = $PropertyValue -replace "`"","" -as [System.String]
                    }
                }
                $Section[$PropertyKey] = $PropertyValue
            }
        }
        return $Section
    }

    #endregion
}

#endregion
#region Class PSFortigateConfigObject
Class PSFortigateConfigObject : PSFortigateConfig {
    #region Properties
    Hidden [PSCustomObject]$PolicyTemplate
    Hidden [PSCustomObject]$AddressTemplate
    Hidden [PSCustomObject]$AddressGroupTemplate
    Hidden [PSCustomObject]$ServiceTemplate
    Hidden [PSCustomObject]$ServiceGroupTemplate

    #endregion
    #region Constructors
    #region Hidden [void]Constructor()
    Hidden [void] Constructor() {
        # Call parent constructor
        ([PSFortigateConfig]$this).Constructor()
        # Setup default templates
        $this.setPolicyTemplate()
        $this.setAddressTemplate()
        $this.setAddressGroupTemplate()
        $this.setServiceTemplate()
        $this.setServiceGroupTemplate()
    }

    #endregion
    #region PSFortigateConfig($Path)
    PSFortigateConfigObject(
        [System.String]$Path
    ) : base($Path) {
        $this.Path = $Path
    }

    #endregion
    #region PSFortigateConfigObject($Path, $Encoding)
    PSFortigateConfigObject(
        [System.String]$Path,
        [System.Text.Encoding]$Encoding
    ) : base($Path, $Encoding) {
        $this.Path = $Path
        $this.Encoding = $Encoding
    }

    #endregion
    #endregion
    #region Hidden [System.String[]]ReadTextFile($Path)
    Hidden [System.String[]]ReadTextFile(
        [System.String]$Path
    ) {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
        $StreamReader = New-Object -TypeName System.IO.StreamReader -ArgumentList $FileStream, $this.Encoding
        return ($StreamReader.ReadToEnd()).Split([Environment]::NewLine)
        $StreamReader.Close()
        $StreamReader.Dispose()
        $FileStream.Close()
        $FileStream.Dispose()
    }

    #endregion
    #region [void]setPolicyTemplate([System.String[]]$Template)
    [void]setPolicyTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; sequence = $null ; policyid = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.PolicyTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setPolicyTemplate()
    [void]setPolicyTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default policy template'
        $Template = @"
    edit "deleteme"
        set name "deleteme"
        set uuid "deleteme"
        set srcintf "deleteme"
        set dstintf "deleteme"
        set srcaddr "deleteme"
        set dstaddr "deleteme"
        set internet-service "deleteme"
        set rtp-nat "deleteme"
        set learning-mode "deleteme"
        set action "deleteme"
        set status "deleteme"
        set schedule "deleteme"
        set schedule-timeout "deleteme"
        set service "deleteme"
        set dscp-match "deleteme"
        set utm-status "deleteme"
        set logtraffic "deleteme"
        set logtraffic-start "deleteme"
        set capture-packet "deleteme"
        set auto-asic-offload "deleteme"
        set np-accelation "deleteme"
        set wanopt "deleteme"
        set webcache "deleteme"
        set session-ttl "deleteme"
        set vlan-cos-fwd "deleteme"
        set vlan-cos-rev "deleteme"
        set wccp "deleteme"
        set disclaimer "deleteme"
        set natip "deleteme"
        set diffserv-forward "deleteme"
        set diffserv-reverse "deleteme"
        set tcp-mss-sender "deleteme"
        set tcp-mss-receiver "deleteme"
        set comments "deleteme"
        set block-notification "deleteme"
        set replacemsg-override-group "deleteme"
        set srcaddr-negate "deleteme"
        set dstaddr-negate "deleteme"
        set service-negate "deleteme"
        set timeout-send-rst "deleteme"
        set captive-portal-exempt "deleteme"
        set ssl-mirror "deleteme"
        set scan-botnet-connections "deleteme"
        set dsri "deleteme"
        set radius-mac-auth-bypass "deleteme"
        set delay-tcp-npu-session "deleteme"
        set traffic-shaper "deleteme"
        set traffic-shaper-reverse "deleteme"
        set per-ip-shaper "deleteme"
        set nat "deleteme"
        set match-vip "deleteme"
        set global-label "deleteme"
        set ips-sensor "deleteme"
        set ssl-ssh-profile "deleteme"
        set dnsfilter-profile "deleteme"
        set profile-protocol-options "deleteme"
        set users "deleteme"
        set groups "deleteme"
        set ippool "deleteme"
        set poolname "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setPolicyTemplate($Template)
    }

    #endregion
    #region [void]setPolicyTemplate($Path)
    [void]setPolicyTemplate(
        [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load policy template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setPolicyTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getPolicy()
    [PSCustomObject[]]getPolicy() {
        $cPolicies = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['firewall policy'].count -gt 0) {
                    foreach ($Policy in $vdom.Value['firewall policy'].GetEnumerator()) {
                        $oPolicy = $this.PolicyTemplate.PsObject.Copy()
                        $oPolicy.vdom = $vdom.Name
                        $oPolicy.policyid = $Policy.Name
#                        $oPolicy.sequence = $Policy.Name

                        foreach ($PolicyOption in $Policy.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} Policy {1} Option {2}' -f $vdom.Name, $Policy.Name, $PolicyOption.Name)
                                $oPolicy.($PolicyOption.Name) = $PolicyOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} Address {1} Option {2} - option not found in policy template' -f $vdom.Name, $Policy.Name, $PolicyOption.Name)
                            }
                        }
                        $cPolicies.Add($oPolicy)
                    }
                }
            }
            return $cPolicies
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setAddressTemplate([System.String[]]$Template)
    [void]setAddressTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.AddressTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setAddressTemplate()
    [void]setAddressTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default address template'
        $Template = @"
    edit "deleteme"
        set uuid "deleteme"
        set type "deleteme"
        set associated-interface "deleteme"
        set subnet "deleteme"
        set start-ip "deleteme"
        set end-ip "deleteme"
        set fqdn "deleteme"
        set wildcard-fqdn "deleteme"
        set comment "deleteme"
        set visibility "deleteme"
        set allow-routing "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setAddressTemplate($Template)
    }

    #endregion
    #region [void]setAddressTemplate($Path)
    [void]setAddressTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load address template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setAddressTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getAddress()
    [PSCustomObject[]]getAddress() {
        $cAddresses = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['firewall address'].count -gt 0) {
                    foreach ($Address in $vdom.Value['firewall address'].GetEnumerator()) {
                        $oAddress = $this.AddressTemplate.PsObject.Copy()
                        $oAddress.vdom = $vdom.Name
                        $oAddress.name = $Address.Name

                        foreach ($AddressOption in $Address.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} Address {1} Option {2}' -f $vdom.Name, $Address.Name, $AddressOption.Name)
                                $oAddress.($AddressOption.Name) = $AddressOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} Address {1} Option {2} - option not found in address template' -f $vdom.Name, $Address.Name, $AddressOption.Name)
                            }
                        }
                        $cAddresses.Add($oAddress)
                    }
                }
            }
            return $cAddresses
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setAddressGroupTemplate([System.String[]]$Template)
    [void]setAddressGroupTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.AddressGroupTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setAddressGroupTemplate()
    [void]setAddressGroupTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default address group template'
        $Template = @"
    edit "deleteme"
        set uuid "deleteme"
        set member "deleteme"
        set comment "deleteme"
        set allow-routing "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setAddressGroupTemplate($Template)
    }

    #endregion
    #region [void]setAddressGroupTemplate($Path)
    [void]setAddressGroupTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load address group template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setAddressGroupTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getAddressGroup()
    [PSCustomObject[]]getAddressGroup() {
        $cAddressGroups = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['firewall addrgrp'].count -gt 0) {
                    foreach ($AddressGroup in $vdom.Value['firewall addrgrp'].GetEnumerator()) {
                        $oAddressGroup = $this.AddressGroupTemplate.PsObject.Copy()
                        $oAddressGroup.vdom = $vdom.Name
                        $oAddressGroup.name = $AddressGroup.Name

                        foreach ($AddressGroupOption in $AddressGroup.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} Address Group {1} Option {2}' -f $vdom.Name, $AddressGroup.Name, $AddressGroupOption.Name)
                                $oAddressGroup.($AddressGroupOption.Name) = $AddressGroupOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} Address Group {1} Option {2} - option not found in address group template' -f $vdom.Name, $AddressGroup.Name, $AddressGroupOption.Name)
                            }
                        }
                        $cAddressGroups.Add($oAddressGroup)
                    }
                }
            }
            return $cAddressGroups
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setServiceTemplate([System.String[]]$Template)
    [void]setServiceTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.ServiceTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setServiceTemplate()
    [void]setServiceTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default service template'
        $Template = @"
    edit "deleteme"
        set proxy "deleteme"
        set category "deleteme"
        set protocol "deleteme"
        set protocol-number "deleteme"
        set visibility "deleteme"
        set tcp-portrange "deleteme"
        set udp-portrange "deleteme"
        set icmptype "deleteme"
        set comment "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setServiceTemplate($Template)
    }

    #endregion
    #region [void]setServiceTemplate($Path)
    [void]setServiceTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load service template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setServiceTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getService()
    [PSCustomObject[]]getService() {
        $cServices = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['firewall service custom'].count -gt 0) {
                    foreach ($Service in $vdom.Value['firewall service custom'].GetEnumerator()) {
                        $oService = $this.ServiceTemplate.PsObject.Copy()
                        $oService.vdom = $vdom.Name
                        $oService.name = $Service.Name

                        foreach ($ServiceOption in $Service.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} Service {1} Option {2}' -f $vdom.Name, $Service.Name, $ServiceOption.Name)
                                $oService.($ServiceOption.Name) = $ServiceOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} Service {1} Option {2} - option not found in service template' -f $vdom.Name, $Service.Name, $ServiceOption.Name)
                            }
                        }
                        $cServices.Add($oService)
                    }
                }
            }
            return $cServices
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setServiceGroupTemplate([System.String[]]$Template)
    [void]setServiceGroupTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.ServiceGroupTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setServiceGroupTemplate()
    [void]setServiceGroupTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default service group template'
        $Template = @"
    edit "deleteme"
       set member "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setServiceGroupTemplate($Template)
    }

    #endregion
    #region [void]setServiceGroupTemplate($Path)
    [void]setServiceGroupTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load service group template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setServiceGroupTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getServiceGroup()
    [PSCustomObject[]]getServiceGroup() {
        $cServiceGroups = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['firewall service group'].count -gt 0) {
                    foreach ($ServiceGroup in $vdom.Value['firewall service group'].GetEnumerator()) {
                        $oServiceGroup = $this.ServiceGroupTemplate.PsObject.Copy()
                        $oServiceGroup.vdom = $vdom.Name
                        $oServiceGroup.name = $ServiceGroup.Name

                        foreach ($ServiceGroupOption in $ServiceGroup.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} ServiceGroup {1} Option {2}' -f $vdom.Name, $ServiceGroup.Name, $ServiceGroupOption.Name)
                                $oServiceGroup.($ServiceGroupOption.Name) = $ServiceGroupOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} ServiceGroup {1} Option {2} - option not found in service group template' -f $vdom.Name, $ServiceGroup.Name, $ServiceGroupOption.Name)
                            }
                        }
                        $cServiceGroups.Add($oServiceGroup)
                    }
                }
            }
            return $cServiceGroups
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
}

#endregion
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
