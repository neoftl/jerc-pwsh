param (
    [string]$TestIdFilter = $null,
    [switch]$ContinueOnFail,
    [switch]$HideSkipped,
    [switch]$Debug
)

. $PSScriptRoot/_PwshTestFramework.ps1

$PwshTest.TestIdFilter = $TestIdFilter
$PwshTest.HideSkipped = $HideSkipped
$PwshTest.ThrowExceptions = -not $ContinueOnFail

function Test-JercFiles ([string]$Id, [string]$Title, [hashtable]$Files, $ResultLogic, [bool]$enabled = $true) {
    $global:ErrorActionPreference = $ContinueOnFail ? 'Continue' : 'Stop'
    $global:DebugPreference = $Debug ? 'Continue' : 'SilentlyContinue'
    
    if (-not $enabled -or (-not $ContinueOnFail -and $PwshTest.TestFailureCount -gt 0)) { return }
    $uid = [Guid]::NewGuid().ToString()
    $dir = "${env:TEMP}/$uid"
    New-Item $dir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    
    $FN = $null
    foreach ($k in $Files.Keys) {
        if (-not $FN) { $FN = $k }
        Set-Content "$dir/$k.json" $Files[$k]
    }
    try {
        (&$PwshTest.Run -Id $Id -Title $Title -Expected $true `
            -TestLogic {
                $result = (Get-JercResources "$dir/$FN.json")
                # TODO: detect warnings
                $global:_lastTestResult = $result
                return (&$ResultLogic $result)
            })
    } finally {
        Remove-Item $dir -Recurse -ErrorAction SilentlyContinue
    }

    $global:ErrorActionPreference = 'Stop'
    $global:DebugPreference = 'SilentlyContinue'
}

function Test-JercResources ([string]$Id, [string]$Title, [string]$json1, $ResultLogic, [string]$json2 = $null, [bool]$enabled = $true) {
    $global:ErrorActionPreference = $ContinueOnFail ? 'Continue' : 'Stop'
    $global:DebugPreference = $Debug ? 'Continue' : 'SilentlyContinue'
    
    if (-not $enabled -or (-not $ContinueOnFail -and $PwshTest.TestFailureCount -gt 0)) { return }
    $dir = $env:TEMP
    $FN = [Guid]::NewGuid().ToString()
    Set-Content "$dir/$FN.json" $json1
    if ($json2) { Set-Content "$dir/file2.json" $json2 }
    (&$PwshTest.Run -Id $Id -Title $Title -Expected $true `
        -TestLogic {
            $result = (Get-JercResources "$dir/$FN.json")
            # TODO: detect warnings
            $global:_lastTestResult = $result
            return (&$ResultLogic $result)
        })
    Remove-Item "$dir/$FN.json"
    Remove-Item "$dir/file2.json" -ErrorAction SilentlyContinue

    $global:ErrorActionPreference = 'Stop'
    $global:DebugPreference = 'SilentlyContinue'
}

function Test-JercParser ([string]$Id, [string]$Title, [string]$json1, $Expected, [string]$json2 = $null, [bool]$enabled = $true) {
    $global:ErrorActionPreference = $ContinueOnFail ? 'Continue' : 'Stop'
    $global:DebugPreference = $Debug ? 'Continue' : 'SilentlyContinue'
    
    if (-not $enabled -or (-not $ContinueOnFail -and $PwshTest.TestFailureCount -gt 0)) { return }
    $dir = $env:TEMP
    $FN = [Guid]::NewGuid().ToString()
    Set-Content "$dir/$FN.json" $json1
    if ($json2) { Set-Content "$dir/file2.json" $json2 }
    (&$PwshTest.Run -Id $Id -Title $Title -Expected $Expected `
        -TestLogic {
            $result = (Get-JercResources "$dir/$FN.json")
            # TODO: detect warnings
            $global:_lastTestResult = $result
            $result = ($result.Test ? $result.Test.Actual : "Missing 'Test' resource.")
            if ($result -and -not ($result -is [string])) {
                $result = (ConvertTo-Json $result -Compress)
            }
            return $result
        })
    Remove-Item "$dir/$FN.json"
    Remove-Item "$dir/file2.json" -ErrorAction SilentlyContinue

    $global:ErrorActionPreference = 'Stop'
    $global:DebugPreference = 'SilentlyContinue'
}

function Test-JercTransformer ([string]$Id, [string]$Title, [Hashtable]$resource, [string]$template, $Expected, [bool]$enabled = $true, [switch]$DisableWarnings) {
    $global:WarningPreference = $DisableWarnings ? 'SilentlyContinue' : 'Continue'
    $global:ErrorActionPreference = $ContinueOnFail ? 'Continue' : 'Stop'
    $global:DebugPreference = $Debug ? 'Continue' : 'SilentlyContinue'
    
    if (-not $enabled -or (-not $ContinueOnFail -and $PwshTest.TestFailureCount -gt 0)) { return }
    (&$PwshTest.Run -Id $Id -Title $Title -Expected $Expected `
        -TestLogic {
            $result = (Convert-JercTemplate $template $resource)
            # TODO: detect warnings
            $global:_lastTestResult = $result
            return $result
        })

    $global:WarningPreference = 'Continue'
    $global:ErrorActionPreference = 'Stop'
    $global:DebugPreference = 'SilentlyContinue'
}