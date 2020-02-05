#region Class PSFortigateConfigObject
Class PSFortigateConfigObject : PSFortigateConfig {
    #region Properties
    Hidden [PSCustomObject]$PolicyTemplate
    Hidden [PSCustomObject]$AddressTemplate
    Hidden [PSCustomObject]$AddressGroupTemplate
    Hidden [PSCustomObject]$ServiceTemplate
    Hidden [PSCustomObject]$ServiceGroupTemplate
    Hidden [PSCustomObject]$LocalUserTemplate
    Hidden [PSCustomObject]$FortitokenTemplate
    Hidden [PSCustomObject]$UserGroupTemplate

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
        $this.setLocalUserTemplate()
        $this.setFortitokenTemplate()
        $this.setUserGroupTemplate()
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

}

#endregion