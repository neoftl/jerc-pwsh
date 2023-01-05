<#
.SYNOPSIS
Returns resources with fully resolved values.

.DESCRIPTION
Resolves Jerc file(s) to final resource values.
Returns a dictionary of resource names, with each a dictionary of key-values.

.PARAMETER File
The Jerc file (JSON) to be processed.

.EXAMPLE
Get-JercResources './resources.jsonc'

.LINK
Implementation information: https://github.com/neoftl/jerc-pwsh
#>
function Get-JercResources ([IO.FileInfo]$File) {
    $resources = (Resolve-JercResources $File)
    $resources.Keys | ForEach-Object {
        $resource = $resources[$_]
        @($resource.Keys) | Where-Object { $_ -and $resource[$_] -and $resource[$_] -is [string] } | ForEach-Object {
            $value = (Convert-JercTemplate $resource[$_] $resource '')

            # Convert to literal
            if ($value.StartsWith('{!}')) {
                # TODO: graceful handling of invalid literals?
                Write-Debug "Parsing '$($value.Substring(3))' as literal."
                $value = (ConvertFrom-Json $value.Substring(3))
            }
    
            $resource[$_] = $value
        }
    }
    return $resources
}
Export-ModuleMember -Function Get-JercResources