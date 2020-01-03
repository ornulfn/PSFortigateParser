properties {
    $ModuleName = "PSFortigateParser"
    $ModuleVersion = '1.1.0'

    $ModuleManifest = @{
        'RootModule'           = $ModuleName
        'ModuleVersion'        = $ModuleVersion
        'CompatiblePSEditions' = 'Core', 'Desktop'
        'Guid'                 = '9782412b-b465-4ac3-a7d6-a18ef388be59'
        'Author'               = 'Ørnulf Nielsen'
        'Copyright'            = '(c) 2020 Ørnulf Nielsen. All rights reserved.'
        'Description'          = 'Parse and create CSV reports from a Fortigate configuration file'
        'PowerShellVersion'    = '5.1'
        'Tags'                 = 'Fortigate','Fortinet','CSV','Parse', 'PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Linux', 'MacOS'
        'LicenseUri'           = 'https://github.com/ornulfn/PSFortigateParser/blob/master/LICENSE'
        'ProjectUri'           = 'https://github.com/ornulfn/PSFortigateParser'
        'ReleaseNotes'         = 'https://github.com/ornulfn/PSFortigateParser/releases'
    }

    $Root = ((Get-Item $PSScriptRoot).Parent).FullName
    $ModuleFolderPath = $Root
    $ExportPath = Join-Path -Path $ModuleFolderPath -ChildPath ("{0}.psm1" -f $ModuleName)
    $CodeSourcePath = Join-Path -Path $Root -ChildPath "src"

    $testMessage = 'Executed Test!'
    $compileMessage = 'Executed Compile!'
    $cleanMessage = 'Executed Clean!'
}

task default -depends Test

task Test -depends Compile, Clean {
    $testMessage
    Write-Host "[TEST][PSM1] Analyze PSM1..." -ForegroundColor RED -BackgroundColor White
    $Results = Invoke-ScriptAnalyzer -Path $ModuleFolderPath -Severity @('Error', 'Warning') -Verbose:$false
    if ($Results) {
        $Results | Format-Table  
        Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'        
    }
}

task Compile -depends Clean {
    $compileMessage

    Write-Host "[BUILD][START] Launching Build Process" -ForegroundColor RED -BackgroundColor White

    if(Test-Path $ExportPath){
        Write-Host "[BUILD][PSM1] PSM1 file detected. Deleting..." -ForegroundColor RED -BackgroundColor White
        Remove-Item -Path $ExportPath -Force
    }
    $Date = Get-Date -Format "yyyy-MM-dd HH:mm"
    "#Generated at $($Date) by Ørnulf Nielsen" | out-File -FilePath $ExportPath -Encoding utf8 -Append

    Write-Host "[BUILD][Code] Loading Class, public and private functions" -ForegroundColor RED -BackgroundColor White

    $PublicClasses = Get-ChildItem -Path "$CodeSourcePath\Classes\" -Filter *.ps1 | sort-object Name
    $PrivateFunctions = Get-ChildItem -Path "$CodeSourcePath\Functions\Private" -Filter *.ps1
    $PublicFunctions = Get-ChildItem -Path "$CodeSourcePath\Functions\Public" -Filter *.ps1

    $MainPSM1Contents = @()
    $MainPSM1Contents += $PublicClasses
    $MainPSM1Contents += $PrivateFunctions
    $MainPSM1Contents += $PublicFunctions

    <#
    Write-Host "[BUILD][START][PRE] Adding Pre content" -ForegroundColor RED -BackgroundColor White
    $PreContentPath = Join-Path -Path $Current -ChildPath "03_PreContent.ps1"
    If($PrecontentPath){
        $file = Get-item $PreContentPath
        Gc $File.FullName | out-File -FilePath $ExportPath -Encoding utf8 -Append

    }else{
        Write-Host "[BUILD][START][POST] No post content file found!" -ForegroundColor RED -BackgroundColor White
    }
    #>
    #Creating PSM1
    Write-Host "[BUILD][START][MAIN PSM1] Building main PSM1" -ForegroundColor RED -BackgroundColor White
    Foreach($file in $MainPSM1Contents){
        Gc $File.FullName | out-File -FilePath $ExportPath -Encoding utf8 -Append    
    }

    <#
    Write-Host "[BUILD][START][POST] Adding post content" -ForegroundColor RED -BackgroundColor White
    $PostContentPath = Join-Path -Path $Current -ChildPath "03_postContent.ps1"
    If($PostContentPath){
        $file = Get-item $PostContentPath
        Gc $File.FullName | out-File -FilePath $ExportPath -Encoding utf8 -Append
    }else{
        Write-Host "[BUILD][START][POST] No post content file found!" -ForegroundColor RED -BackgroundColor White
    }
    #>
    Write-Host "[BUILD][START][PSD1] Adding functions to export" -ForegroundColor RED -BackgroundColor White

    $FunctionsToExport = $PublicFunctions.BaseName
    $Manifest = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psd1"

    Update-ModuleManifest -Path $Manifest -FunctionsToExport $FunctionsToExport @ModuleManifest
    (Get-Content -Path $Manifest) | Set-Content -Path $Manifest -Encoding UTF8

    Write-Host "[BUILD][END][MAIN PSM1] building main PSM1 " -ForegroundColor RED -BackgroundColor White

    Write-Host "[BUILD][END]End of Build Process" -ForegroundColor RED -BackgroundColor White
}

task Clean {
    $cleanMessage
}

task ? -Description "Helper to display task info" {
    Write-Documentation
}
