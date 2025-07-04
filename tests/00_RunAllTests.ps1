param (
    [string]$Filter = $null,
    [switch]$ContinueOnFail,
    [switch]$HideSkipped,
    [switch]$Debug
)

. $PSScriptRoot/_JercTestFramework.ps1 -TestIdFilter:$Filter -ContinueOnFail:$ContinueOnFail -Debug:$Debug -HideSkipped:$HideSkipped

Remove-Module Jerc -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot/../src/Jerc.psm1

. $PSScriptRoot/JercTests.Basics.ps1
. $PSScriptRoot/JercTests.Aspects.ps1
. $PSScriptRoot/JercTests.Functions.ps1
. $PSScriptRoot/JercTests.Substrings.ps1
. $PSScriptRoot/JercTests.Transform.ps1
. $PSScriptRoot/JercTests.Includes.ps1
. $PSScriptRoot/JercTests.Correctness.ps1

(&$PwshTest.ShowSummary)