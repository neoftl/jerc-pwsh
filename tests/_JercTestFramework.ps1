param (
    [string]$TestIdFilter = $null,
    [switch]$ContinueOnFail,
    [switch]$Debug
)

. $PSScriptRoot/_PwshTestFramework.ps1

$PwshTest.TestIdFilter = $TestIdFilter
$PwshTest.ThrowExceptions = -not $ContinueOnFail

function Test-JercResources ([string]$Id, [string]$Title, [string]$json1, $ResultLogic, [string]$json2 = $null, [bool]$enabled = $true) {
    $global:ErrorActionPreference = $ContinueOnFail ? 'Continue' : 'Stop'
    $global:DebugPreference = $Debug ? 'Continue' : 'SilentlyContinue'
    
    if (-not $enabled -or (-not $ContinueOnFail -and $PwshTest.TestFailureCount -gt 0)) { return }
    Set-Content "$PSScriptRoot/file1.json" $json1
    if ($json2) { Set-Content "$PSScriptRoot/file2.json" $json2 }
    (&$PwshTest.Run -Id $Id -Title $Title -Expected $true `
        -TestLogic {
            $result = (Get-JercResources "$PSScriptRoot/file1.json")
            # TODO: detect warnings
            $global:_lastTestResult = $result
            return (&$ResultLogic $result)
        })
    Remove-Item "$PSScriptRoot/file1.json"
    Remove-Item "$PSScriptRoot/file2.json" -ErrorAction SilentlyContinue

    $global:ErrorActionPreference = 'Stop'
    $global:DebugPreference = 'SilentlyContinue'
}

function Test-JercParser ([string]$Id, [string]$Title, [string]$json1, $Expected, [string]$json2 = $null, [bool]$enabled = $true) {
    $global:ErrorActionPreference = $ContinueOnFail ? 'Continue' : 'Stop'
    $global:DebugPreference = $Debug ? 'Continue' : 'SilentlyContinue'
    
    if (-not $enabled -or (-not $ContinueOnFail -and $PwshTest.TestFailureCount -gt 0)) { return }
    Set-Content "$PSScriptRoot/file1.json" $json1
    if ($json2) { Set-Content "$PSScriptRoot/file2.json" $json2 }
    (&$PwshTest.Run -Id $Id -Title $Title -Expected $Expected `
        -TestLogic {
            $result = (Get-JercResources "$PSScriptRoot/file1.json")
            # TODO: detect warnings
            $global:_lastTestResult = $result
            $result = ($result.Test ? $result.Test.Actual : "Missing 'Test' resource.")
            if ($result -and -not ($result -is [string])) {
                $result = (ConvertTo-Json $result -Compress)
            }
            return $result
        })
    Remove-Item "$PSScriptRoot/file1.json"
    Remove-Item "$PSScriptRoot/file2.json" -ErrorAction SilentlyContinue

    $global:ErrorActionPreference = 'Stop'
    $global:DebugPreference = 'SilentlyContinue'
}

function Test-JercTransformer ([string]$Id, [string]$Title, [Hashtable]$resource, [string]$template, $Expected, [bool]$enabled = $true) {
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

    $global:ErrorActionPreference = 'Stop'
    $global:DebugPreference = 'SilentlyContinue'
}