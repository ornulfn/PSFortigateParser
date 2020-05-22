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