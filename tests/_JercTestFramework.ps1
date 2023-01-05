param (
    [switch]$ContinueOnFail,
    [switch]$Debug
)

. $PSScriptRoot/_PwshTestFramework.ps1

$PwshTest.ThrowExceptions = -not $ContinueOnFail

$ErrorActionPreference = $ContinueOnFail ? 'Continue' : 'Stop'
$DebugPreference = $Debug ? 'Continue' : 'SilentlyContinue'

function Test-JercParser ([string]$Title, [string]$json1, $Expected, [string]$json2 = $null, [bool]$enabled = $true) {
    if (-not $enabled -or (-not $ContinueOnFail -and $PwshTest.TestFailureCount -gt 0)) { return }
    Set-Content "$PSScriptRoot/file1.json" $json1
    if ($json2) { Set-Content "$PSScriptRoot/file2.json" $json2 }
    (&$PwshTest.Run $Title $Expected `
        {
            $result = (Get-JercResources "$PSScriptRoot/file1.json")
            # TODO: detect warnings
            $global:_lastTestResult = $result
            return ($result.Test ? $result.Test.Actual : "Missing 'Test' resource.")
        })
    Remove-Item "$PSScriptRoot/file1.json"
    Remove-Item "$PSScriptRoot/file2.json" -ErrorAction SilentlyContinue
}

function Test-JercTransformer ([string]$Title, [Hashtable]$resource, [string]$template, $Expected, [bool]$enabled = $true) {
    if (-not $enabled -or (-not $ContinueOnFail -and $PwshTest.TestFailureCount -gt 0)) { return }
    (&$PwshTest.Run $Title $Expected `
        {
            $result = (Convert-JercTemplate $template $resource)
            # TODO: detect warnings
            $global:_lastTestResult = $result
            return $result
        })
}