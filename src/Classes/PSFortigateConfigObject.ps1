#region Class PSFortigateConfigObject
Class PSFortigateConfigObject : PSFortigateConfig {
    #region Properties
    Hidden [PSCustomObject]$PolicyTemplate
    Hidden [PSCustomObject]$AddressTemplate
    Hidden [PSCustomObject]$AddressGroupTemplate

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
        $Options = [Ordered]@{ vdom = $null; sequence = $null }
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
                        $oPolicy.sequence = $Policy.Name

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
    #region [void]setAddressTemplate([System.String[]]$Template)
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
}

#endregion