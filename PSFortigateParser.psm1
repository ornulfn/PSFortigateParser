#Generated at 2020-05-22 20:35 by Ørnulf Nielsen
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
                    if ($Matches.section -eq "firewall policy" -or $Matches.section -eq "firewall proxy-policy" ) {
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
                if ($PropertyKey -eq "uuid" -and $this.inPolicySection) {
                    $Section['sequence'] = $this.PolicySequence
                }

                # Remove double quotes - use array if multi-valued
                if (($this.inServiceSection -and $PropertyKey -like "*-portrange") -or ($this.inPolicySection -and $PropertyKey -like "internet-service-id")) {
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
    Hidden [PSCustomObject]$ProxyPolicyTemplate
    Hidden [PSCustomObject]$AddressTemplate
    Hidden [PSCustomObject]$AddressGroupTemplate
    Hidden [PSCustomObject]$ServiceTemplate
    Hidden [PSCustomObject]$ServiceGroupTemplate
    Hidden [PSCustomObject]$LocalUserTemplate
    Hidden [PSCustomObject]$FortitokenTemplate
    Hidden [PSCustomObject]$UserGroupTemplate
    Hidden [PSCustomObject]$InterfaceTemplate
    Hidden [PSCustomObject]$IPsecPhase1Template
    Hidden [PSCustomObject]$IPsecPhase2Template
    Hidden [PSCustomObject]$SystemZoneTemplate
    Hidden [PSCustomObject]$RouterStaticTemplate

    #endregion
    #region Constructors
    #region Hidden [void]Constructor()
    Hidden [void] Constructor() {
        # Call parent constructor
        ([PSFortigateConfig]$this).Constructor()
        # Setup default templates
        $this.setPolicyTemplate()
        $this.setProxyPolicyTemplate()
        $this.setAddressTemplate()
        $this.setAddressGroupTemplate()
        $this.setServiceTemplate()
        $this.setServiceGroupTemplate()
        $this.setLocalUserTemplate()
        $this.setFortitokenTemplate()
        $this.setUserGroupTemplate()
        $this.setInterfaceTemplate()
        $this.setIPsecPhase1Template()
        $this.setIPsecPhase2Template()
        $this.setSystemZoneTemplate()
        $this.setRouterStaticTemplate()
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
        elseif ($this.Config['firewall policy'].count -gt 0) {
            foreach ($Policy in $this.Config['firewall policy'].GetEnumerator()) {
                $oPolicy = $this.PolicyTemplate.PsObject.Copy()
                $oPolicy.vdom = ""
                $oPolicy.policyid = $Policy.Name

                foreach ($PolicyOption in $Policy.Value.GetEnumerator()) {
                    try {
                        Write-Debug ('PSFortigateConfigObject: Adding vDom {0} Policy {1} Option {2}' -f "No vDom", $Policy.Name, $PolicyOption.Name)
                        $oPolicy.($PolicyOption.Name) = $PolicyOption.Value
                    }
                    catch {
                        Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} Address {1} Option {2} - option not found in policy template' -f "No vDom", $Policy.Name, $PolicyOption.Name)
                    }
                }
                $cPolicies.Add($oPolicy)
            }
            return $cPolicies
        }
        Write-Debug ('PSFortigateConfigObject: No firewall policy found')
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
        set comment "deleteme"
        set visibility "deleteme"
        set associated-interface "deleteme"
        set color "deleteme"
        set allow-routing "deleteme"
        set subnet "deleteme"
        set start-ip "deleteme"
        set end-ip "deleteme"
        set wildcard-fqdn "deleteme"
        set fqdn "deleteme"
        set cache-ttl "deleteme"
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
        set visibility "deleteme"
        set color "deleteme"
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
        set helper "deleteme"
        set check-reset-range "deleteme"
        set comment "deleteme"
        set color "deleteme"
        set visibility "deleteme"
        set app-service-type disable
        set iprange "deleteme"
        set fqdn "deleteme"
        set tcp-portrange "deleteme"
        set udp-portrange "deleteme"
        set sctp-portrange "deleteme"
        set tcp-halfclose-timer "deleteme"
        set tcp-halfopen-timer "deleteme"
        set tcp-timewait-timer "deleteme"
        set udp-idle-timer "deleteme"
        set session-ttl "deleteme"
        set icmptype "deleteme"
        set icmpcode "deleteme"
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
        set proxy "deleteme"
        set comment "deleteme"
        set color "deleteme"
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
    #region [void]setLocalUserTemplate([System.String[]]$Template)
    [void]setLocalUserTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.LocalUserTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setLocalUserTemplate()
    [void]setLocalUserTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default local user template'
        $Template = @"
    edit "deleteme"
        set status "deleteme"
        set type "deleteme"
        set two-factor "deleteme"
        set fortitoken "deleteme"
        set email-to "deleteme"
        set sms-server "deleteme"
        set sms-phone "deleteme"
        set passwd-policy "deleteme"
        set passwd-time "deleteme"
        set authtimeout "deleteme"
        set auth-concurrent-override "deleteme"
        set passwd "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setLocalUserTemplate($Template)
    }

    #endregion
    #region [void]setLocalUserTemplate($Path)
    [void]setLocalUserTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load local user template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setLocalUserTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getLocalUser()
    [PSCustomObject[]]getLocalUser() {
        $cLocalUsers = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['user local'].count -gt 0) {
                    foreach ($LocalUser in $vdom.Value['user local'].GetEnumerator()) {
                        $oLocalUser = $this.LocalUserTemplate.PsObject.Copy()
                        $oLocalUser.vdom = $vdom.Name
                        $oLocalUser.name = $LocalUser.Name

                        foreach ($LocalUserOption in $LocalUser.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} LocalUser {1} Option {2}' -f $vdom.Name, $LocalUser.Name, $LocalUserOption.Name)
                                $oLocalUser.($LocalUserOption.Name) = $LocalUserOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} LocalUser {1} Option {2} - option not found in local user template' -f $vdom.Name, $LocalUser.Name, $LocalUserOption.Name)
                            }
                        }
                        $cLocalUsers.Add($oLocalUser)
                    }
                }
            }
            return $cLocalUsers
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setFortitokenTemplate([System.String[]]$Template)
    [void]setFortitokenTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.FortitokenTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setFortitokenTemplate()
    [void]setFortitokenTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default fortitoken template'
        $Template = @"
    edit "deleteme"
        set status "deleteme"
        set comments "deleteme"
        set license "deleteme"
        set activation-code "deleteme"
        set activation-expire "deleteme"
        set reg-id "deleteme"
        set os-ver "deleteme"
        set seed "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setFortitokenTemplate($Template)
    }

    #endregion
    #region [void]setFortitokenTemplate($Path)
    [void]setFortitokenTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load fortitoken template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setFortitokenTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getFortitoken()
    [PSCustomObject[]]getFortitoken() {
        $cFortitokens = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['user fortitoken'].count -gt 0) {
                    foreach ($Fortitoken in $vdom.Value['user fortitoken'].GetEnumerator()) {
                        $oFortitoken = $this.FortitokenTemplate.PsObject.Copy()
                        $oFortitoken.vdom = $vdom.Name
                        $oFortitoken.name = $Fortitoken.Name

                        foreach ($FortitokenOption in $Fortitoken.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} Fortitoken {1} Option {2}' -f $vdom.Name, $Fortitoken.Name, $FortitokenOption.Name)
                                $oFortitoken.($FortitokenOption.Name) = $FortitokenOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} Fortitoken {1} Option {2} - option not found in fortitoken template' -f $vdom.Name, $Fortitoken.Name, $FortitokenOption.Name)
                            }
                        }
                        $cFortitokens.Add($oFortitoken)
                    }
                }
            }
            return $cFortitokens
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setUserGroupTemplate([System.String[]]$Template)
    [void]setUserGroupTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.UserGroupTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setUserGroupTemplate()
    [void]setUserGroupTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default user group template'
        $Template = @"
    edit "deleteme"
        set group-type "deleteme"
        set authtimeout "deleteme"
        set auth-concurrent-override "deleteme"
        set http-digest-realm "deleteme"
        set user-id "deleteme"
        set password "deleteme"
        set user-name "deleteme"
        set sponsor "deleteme"
        set company "deleteme"
        set email "deleteme"
        set mobile-phone "deleteme"
        set expire-type "deleteme"
        set expire "deleteme"
        set max-accounts "deleteme"
        set multiple-guest-add "deleteme"
        set member "deleteme"
        set sso-attribute-value "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setUserGroupTemplate($Template)
    }

    #endregion
    #region [void]setUserGroupTemplate($Path)
    [void]setUserGroupTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load user group template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setUserGroupTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getUserGroup()
    [PSCustomObject[]]getUserGroup() {
        $cUserGroups = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['user group'].count -gt 0) {
                    foreach ($UserGroup in $vdom.Value['user group'].GetEnumerator()) {
                        $oUserGroup = $this.UserGroupTemplate.PsObject.Copy()
                        $oUserGroup.vdom = $vdom.Name
                        $oUserGroup.name = $UserGroup.Name

                        foreach ($UserGroupOption in $UserGroup.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} User Group {1} Option {2}' -f $vdom.Name, $UserGroup.Name, $UserGroupOption.Name)
                                $oUserGroup.($UserGroupOption.Name) = $UserGroupOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} User Group {1} Option {2} - option not found in user group template' -f $vdom.Name, $UserGroup.Name, $UserGroupOption.Name)
                            }
                        }
                        $cUserGroups.Add($oUserGroup)
                    }
                }
            }
            return $cUserGroups
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setInterfaceTemplate([System.String[]]$Template)
    [void]setInterfaceTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.InterfaceTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setInterfaceTemplate()
    [void]setInterfaceTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default interface template'
        $Template = @"
    edit "deleteme"
        set vdom "deleteme"
        set fortilink "deleteme"
        set mode "deleteme"
        set distance "deleteme"
        set priority "deleteme"
        set dhcp-relay-service "deleteme"
        set allowaccess "deleteme"
        set fail-detect "deleteme"
        set arpforward "deleteme"
        set broadcast-forward "deleteme"
        set bfd "deleteme"
        set l2forward "deleteme"
        set vlanforward "deleteme"
        set stpforward "deleteme"
        set ips-sniffer-mode "deleteme"
        set ident-accept "deleteme"
        set ipmac "deleteme"
        set subst "deleteme"
        set substitute-dst-mac "deleteme"
        set status "deleteme"
        set netbios-forward "deleteme"
        set wins-ip "deleteme"
        set type "deleteme"
        set netflow-sampler "deleteme"
        set sflow-sampler "deleteme"
        set scan-botnet-connections "deleteme"
        set src-check "deleteme"
        set sample-rate "deleteme"
        set polling-interval "deleteme"
        set sample-direction "deleteme"
        set tcp-mss "deleteme"
        set inbandwidth "deleteme"
        set outbandwidth "deleteme"
        set spillover-threshold "deleteme"
        set ingress-spillover-threshold "deleteme"
        set weight "deleteme"
        set external "deleteme"
        set description "deleteme"
        set alias "deleteme"
        set security-mode "deleteme"
        set device-identification "deleteme"
        set fortiheartbeat "deleteme"
        set estimated-upstream-bandwidth "deleteme"
        set estimated-downstream-bandwidth "deleteme"
        set vrrp-virtual-mac "deleteme"
        set snmp-index "deleteme"
        set preserve-session-route "deleteme"
        set auto-auth-extension-device "deleteme"
        set ap-discover "deleteme"
        set dhcp-client-identifier "deleteme"
        set dhcp-renew-time "deleteme"
        set defaultgw "deleteme"
        set dns-server-override "deleteme"
        set speed "deleteme"
        set mtu-override "deleteme"
        set wccp "deleteme"
        set drop-overlapped-fragment "deleteme"
        set drop-fragment "deleteme"
        set pptp-client "deleteme"
        set role "deleteme"
        set ip "deleteme"
        set icmp-redirect "deleteme"
        set lldp-transmission "deleteme"
        set secondary-IP "deleteme"
        set remote-ip "deleteme"
        set interface "deleteme"
        set explicit-web-proxy "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setInterfaceTemplate($Template)
    }

    #endregion
    #region [void]setInterfaceTemplate($Path)
    [void]setInterfaceTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load interface template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setInterfaceTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getInterface()
    [PSCustomObject[]]getInterface() {
        $cInterfaces = New-Object System.Collections.ArrayList
        if ($this.Config['global']['system interface'].count -gt 0) {
            foreach ($Interface in $this.Config['global']['system interface'].GetEnumerator()) {
                $oInterface = $this.InterfaceTemplate.PsObject.Copy()
                $oInterface.name = $Interface.Name

                foreach ($InterfaceOption in $Interface.Value.GetEnumerator()) {
                    try {
                        Write-Debug ('PSFortigateConfigObject: Adding Interface {0} Option {1}' -f $Interface.Name, $InterfaceOption.Name)
                        $oInterface.($InterfaceOption.Name) = $InterfaceOption.Value
                    }
                    catch {
                        Write-Debug ('PSFortigateConfigObject: Skipping Interface {0} Option {1} - option not found in interface template' -f $Interface.Name, $InterfaceOption.Name)
                    }
                }
                $cInterfaces.Add($oInterface)
            }
            return $cInterfaces
        }
        Write-Debug ('PSFortigateConfigObject: No Interfaces found')
        return $null
    }

    #endregion
    #region [void]setIPsecPhase1Template([System.String[]]$Template)
    [void]setIPsecPhase1Template(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.IPsecPhase1Template = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setIPsecPhase1Template()
    [void]setIPsecPhase1Template() {
        Write-Debug 'PSFortigateConfigObject: Set default ipsec phase1 template'
        $Template = @"
    edit "deleteme"
        set type "deleteme"
        set interface "deleteme"
        set ip-version "deleteme"
        set ike-version "deleteme"
        set local-gw "deleteme"
        set keylife "deleteme"
        set authmethod "deleteme"
        set authmethod-remote "deleteme"
        set peertype "deleteme"
        set passive-mode "deleteme"
        set exchange-interface-ip "deleteme"
        set mode-cfg "deleteme"
        set proposal "deleteme"
        set localid "deleteme"
        set localid-type "deleteme"
        set auto-negotiate "deleteme"
        set negotiate-timeout "deleteme"
        set fragmentation "deleteme"
        set dpd "deleteme"
        set forticlient-enforcement "deleteme"
        set comments "deleteme"
        set npu-offload "deleteme"
        set dhgrp "deleteme"
        set suite-b "deleteme"
        set eap "deleteme"
        set wizard-type "deleteme"
        set reauth "deleteme"
        set idle-timeout "deleteme"
        set ha-sync-esp-seqno "deleteme"
        set auto-discovery-sender "deleteme"
        set auto-discovery-receiver "deleteme"
        set auto-discovery-forwarder "deleteme"
        set encapsulation "deleteme"
        set nattraversal "deleteme"
        set fragmentation-mtu "deleteme"
        set childless-ike "deleteme"
        set rekey "deleteme"
        set remote-gw "deleteme"
        set monitor "deleteme"
        set add-gw-route "deleteme"
        set psksecret "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setIPsecPhase1Template($Template)
    }

    #endregion
    #region [void]setIPsecPhase1Template($Path)
    [void]setIPsecPhase1Template(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load ipsec phase1 template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setIPsecPhase1Template($Template)
    }

    #endregion
    #region [PSCustomObject[]]getIPsecPhase1()
    [PSCustomObject[]]getIPsecPhase1() {
        $cIPsecPhase1s = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['vpn ipsec phase1-interface'].count -gt 0) {
                    foreach ($IPsecPhase1 in $vdom.Value['vpn ipsec phase1-interface'].GetEnumerator()) {
                        $oIPsecPhase1 = $this.IPsecPhase1Template.PsObject.Copy()
                        $oIPsecPhase1.vdom = $vdom.Name
                        $oIPsecPhase1.name = $IPsecPhase1.Name

                        foreach ($IPsecPhase1Option in $IPsecPhase1.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} IPsec Phase1 {1} Option {2}' -f $vdom.Name, $IPsecPhase1.Name, $IPsecPhase1Option.Name)
                                $oIPsecPhase1.($IPsecPhase1Option.Name) = $IPsecPhase1Option.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} IPSec Phase1 {1} Option {2} - option not found in ipsec phase1 template' -f $vdom.Name, $IPsecPhase1.Name, $IPsecPhase1Option.Name)
                            }
                        }
                        $cIPsecPhase1s.Add($oIPsecPhase1)
                    }
                }
            }
            return $cIPsecPhase1s
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setIPsecPhase2Template([System.String[]]$Template)
    [void]setIPsecPhase2Template(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.IPsecPhase2Template = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setIPsecPhase2Template()
    [void]setIPsecPhase2Template() {
        Write-Debug 'PSFortigateConfigObject: Set default ipsec phase2 template'
        $Template = @"
    edit "deleteme"
        set phase1name "deleteme"
        set proposal "deleteme"
        set pfs "deleteme"
        set dhgrp "deleteme"
        set replay "deleteme"
        set auto-negotiate "deleteme"
        set auto-discovery-sender "deleteme"
        set auto-discovery-forwarder "deleteme"
        set keylife-type "deleteme"
        set encapsulation "deleteme"
        set comments "deleteme"
        set protocol "deleteme"
        set src-addr-type "deleteme"
        set src-port "deleteme"
        set dst-addr-type "deleteme"
        set dst-port "deleteme"
        set keylifeseconds "deleteme"
        set src-name "deleteme"
        set dst-name "deleteme"
        set src-subnet "deleteme"
        set dst-subnet "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setIPsecPhase2Template($Template)
    }

    #endregion
    #region [void]setIPsecPhase2Template($Path)
    [void]setIPsecPhase2Template(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load ipsec phase2 template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setIPsecPhase2Template($Template)
    }

    #endregion
    #region [PSCustomObject[]]getIPsecPhase2()
    [PSCustomObject[]]getIPsecPhase2() {
        $cIPsecPhase2s = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['vpn ipsec phase2-interface'].count -gt 0) {
                    foreach ($IPsecPhase2 in $vdom.Value['vpn ipsec phase2-interface'].GetEnumerator()) {
                        $oIPsecPhase2 = $this.IPsecPhase2Template.PsObject.Copy()
                        $oIPsecPhase2.vdom = $vdom.Name
                        $oIPsecPhase2.name = $IPsecPhase2.Name

                        foreach ($IPsecPhase2Option in $IPsecPhase2.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} IPsec Phase2 {1} Option {2}' -f $vdom.Name, $IPsecPhase2.Name, $IPsecPhase2Option.Name)
                                $oIPsecPhase2.($IPsecPhase2Option.Name) = $IPsecPhase2Option.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} IPsec Phase2 {1} Option {2} - option not found in ipsec phase2 template' -f $vdom.Name, $IPsecPhase2.Name, $IPsecPhase2Option.Name)
                            }
                        }
                        $cIPsecPhase2s.Add($oIPsecPhase2)
                    }
                }
            }
            return $cIPsecPhase2s
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setSystemZoneTemplate([System.String[]]$Template)
    [void]setSystemZoneTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.SystemZoneTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setSystemZoneTemplate()
    [void]setSystemZoneTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default system zone template'
        $Template = @"
    edit "deleteme"
        set intrazone "deleteme"
        set interface "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setSystemZoneTemplate($Template)
    }

    #endregion
    #region [void]setSystemZoneTemplate($Path)
    [void]setSystemZoneTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load system zone template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setSystemZoneTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getSystemZone()
    [PSCustomObject[]]getSystemZone() {
        $cSystemZones = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['system zone'].count -gt 0) {
                    foreach ($SystemZone in $vdom.Value['system zone'].GetEnumerator()) {
                        $oSystemZone = $this.SystemZoneTemplate.PsObject.Copy()
                        $oSystemZone.vdom = $vdom.Name
                        $oSystemZone.name = $SystemZone.Name

                        foreach ($SystemZoneOption in $SystemZone.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} System Zone {1} Option {2}' -f $vdom.Name, $SystemZone.Name, $SystemZoneOption.Name)
                                $oSystemZone.($SystemZoneOption.Name) = $SystemZoneOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} System Zone {1} Option {2} - option not found in router static template' -f $vdom.Name, $SystemZone.Name, $SystemZoneOption.Name)
                            }
                        }
                        $cSystemZones.Add($oSystemZone)
                    }
                }
            }
            return $cSystemZones
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setRouterStaticTemplate([System.String[]]$Template)
    [void]setRouterStaticTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; name = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.RouterStaticTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setRouterStaticTemplate()
    [void]setRouterStaticTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default router static template'
        $Template = @"
    edit "deleteme"
        set status "deleteme"
        set dst "deleteme"
        set gateway "deleteme"
        set distance "deleteme"
        set weight "deleteme"
        set priority "deleteme"
        set device "deleteme"
        set comment "deleteme"
        set blackhole "deleteme"
        set dynamic-gateway "deleteme"
        set virtual-wan-link "deleteme"
        set dstaddr "deleteme"
        set internet-service "deleteme"
        set internet-service-custom "deleteme"
        set link-monitor-exempt "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setRouterStaticTemplate($Template)
    }

    #endregion
    #region [void]setRouterStaticTemplate($Path)
    [void]setRouterStaticTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load router static template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setRouterStaticTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getRouterStatic()
    [PSCustomObject[]]getRouterStatic() {
        $cRouterStatics = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['router static'].count -gt 0) {
                    foreach ($RouterStatic in $vdom.Value['router static'].GetEnumerator()) {
                        $oRouterStatic = $this.RouterStaticTemplate.PsObject.Copy()
                        $oRouterStatic.vdom = $vdom.Name
                        $oRouterStatic.name = $RouterStatic.Name

                        foreach ($RouterStaticOption in $RouterStatic.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} Router Static {1} Option {2}' -f $vdom.Name, $RouterStatic.Name, $RouterStaticOption.Name)
                                $oRouterStatic.($RouterStaticOption.Name) = $RouterStaticOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} Router Static {1} Option {2} - option not found in router static template' -f $vdom.Name, $RouterStatic.Name, $RouterStaticOption.Name)
                            }
                        }
                        $cRouterStatics.Add($oRouterStatic)
                    }
                }
            }
            return $cRouterStatics
        }
        Write-Debug ('PSFortigateConfigObject: No vDom found')
        return $null
    }

    #endregion
    #region [void]setProxyPolicyTemplate([System.String[]]$Template)
    [void]setProxyPolicyTemplate(
        [System.String[]]$Template
    ) {
        # Columns are displayed according to order in template
        $Options = [Ordered]@{ vdom = $null; sequence = $null ; policyid = $null }
        foreach ($Line in $Template) {
            if ($Line -match "^(\s*)set (?<Option>[^\s]+)\s+(?<Value>.*)$") {
                $Options.add($Matches.Option, $null)
            }
        }
        $this.ProxyPolicyTemplate = New-Object -TypeName "PSCustomObject" -Property $Options
    }

    #endregion
    #region [void]setProxyPolicyTemplate()
    [void]setProxyPolicyTemplate() {
        Write-Debug 'PSFortigateConfigObject: Set default proxy policy template'
        $Template = @"
    edit "deleteme"
        set status "deleteme"
        set proxy "deleteme"
        set dstintf "deleteme"
        set srcaddr "deleteme"
        set dstaddr "deleteme"
        set internet-service "deleteme"
        set internet-service-id "deleteme"
        set service "deleteme"
        set action "deleteme"
        set schedule "deleteme"
        set logtraffic "deleteme"
        set logtraffic-start "deleteme"
    next
"@.Split([Environment]::NewLine)
        $this.setProxyPolicyTemplate($Template)
    }

    #endregion
    #region [void]setProxyPolicyTemplate($Path)
    [void]setProxyPolicyTemplate(
            [System.String]$Path
    ) {
        Write-Debug ('PSFortigateConfigObject: Load proxy policy template from {0}' -f $Path)
        $Template = $this.ReadTextFile($Path)
        $this.setProxyPolicyTemplate($Template)
    }

    #endregion
    #region [PSCustomObject[]]getProxyPolicy()
    [PSCustomObject[]]getProxyPolicy() {
        $cProxyPolicys = New-Object System.Collections.ArrayList
        if ($this.Config['vdom'].count -gt 0) {
            foreach ($vdom in $this.Config['vdom'].GetEnumerator()) {
                if ($vdom.Value['firewall proxy-policy'].count -gt 0) {
                    foreach ($ProxyPolicy in $vdom.Value['firewall proxy-policy'].GetEnumerator()) {
                        $oProxyPolicy = $this.ProxyPolicyTemplate.PsObject.Copy()
                        $oProxyPolicy.vdom = $vdom.Name
                        $oProxyPolicy.policyid = $ProxyPolicy.Name

                        foreach ($ProxyPolicyOption in $ProxyPolicy.Value.GetEnumerator()) {
                            try {
                                Write-Debug ('PSFortigateConfigObject: Adding vDom {0} Proxy Policy {1} Option {2}' -f $vdom.Name, $ProxyPolicy.Name, $ProxyPolicyOption.Name)
                                $oProxyPolicy.($ProxyPolicyOption.Name) = $ProxyPolicyOption.Value
                            }
                            catch {
                                Write-Debug ('PSFortigateConfigObject: Skipping vDom {0} Proxy Policy {1} Option {2} - option not found in proxy policy template' -f $vdom.Name, $ProxyPolicy.Name, $ProxyPolicyOption.Name)
                            }
                        }
                        $cProxyPolicys.Add($oProxyPolicy)
                    }
                }
            }
            return $cProxyPolicys
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
