<#
.SYNOPSIS
Returns resources with fully resolved values.

.DESCRIPTION
Resolves Jerc file(s) to final resource values.
Returns a dictionary of resource names, with each a dictionary of key-values.

.PARAMETER FilesOrHashtables
The array of Jerc files (JSON) or hashtables to be processed.

.EXAMPLE
Get-JercResources './resources.jsonc'

.LINK
Implementation information: https://github.com/neoftl/jerc-pwsh
#>
function Get-JercResources ($FilesOrHashtables) {
    $resources = [hashtable](Resolve-JercResources $FilesOrHashtables)
    $resources.Keys | ForEach-Object {
        $resource = $resources[$_]
        $resource['.key'] = $_
        @($resource.Keys) | Where-Object { $_ -and $resource[$_] -and $resource[$_] -is [string] } | ForEach-Object {
            $value = (Convert-JercTemplate $resource[$_] $resource '')

            # Convert to literal
            if ($value -eq '{null:}') {
                $value = $null
            } elseif ($value.StartsWith('{!}')) {
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