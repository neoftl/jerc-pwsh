#
# JERC-PWSH v0.1
# https://github.com/neoftl/jerc-pwsh
#
# Powershell Core 7+ implementation of Json Extensible Resource Configuration v0.2
# https://github.com/neoftl/jerc-pwsh/blob/main/standard/spec.md
#

if (-not $PSVersionTable -or $PSVersionTable.PSVersion -lt 7) {
    Write-Error "JSON Configuration Parser v2 requires Powershell Core 7. You currently have Powershell $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion). Please upgrade."
    return
}

. $PSScriptRoot/_StringBuilder.ps1

. $PSScriptRoot/Get-JercResources.ps1
. $PSScriptRoot/Resolve-JercResources.ps1
. $PSScriptRoot/Resolve-JercFiles.ps1
. $PSScriptRoot/Convert-JercTemplate.ps1