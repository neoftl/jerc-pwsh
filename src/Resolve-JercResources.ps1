<#
.SYNOPSIS
Returns Jerc file structure with aspects resolved.

.DESCRIPTION
Resolves Jerc file(s) and resource aspects (if any).
Returns a dictionary of resource names, with each a dictionary of key-values.
Jerc templates will not be transformed.

This command is intended for use in diagnosing unexpected configuration values.
For actual use of Jerc resources, see the Get-JercResources command.

.PARAMETER FilesOrHashtables
The array of Jerc files (JSON) or hashtables to be processed.

.EXAMPLE
Resolve-JercResources './resources.jsonc'

.LINK
Get-JercResources

.LINK
Implementation information: https://github.com/neoftl/jerc-pwsh
#>
function Resolve-JercResources ($FilesOrHashtables) {
    $config = [hashtable](Resolve-JercFiles $FilesOrHashtables)
    if (-not $config.ContainsKey('aspects')) {
        $config.'aspects' = @{}
    }
    if (-not $config.ContainsKey('resources')) {
        $config.'resources' = @{}
    }

    $config.resources.Keys | ForEach-Object {
        Write-Debug "Resolving resource '$_'."
        $key = $_
        $resource = $config.resources[$_]
        if ($null -eq $resource) {
            # Remove resource
            return
        }
        if (-not $resource.ContainsKey('.aspects')) {
            $resource.'.aspects' = [string[]]::new(0)
        }
        else {
            [Array]::Reverse($resource.'.aspects')
        }
        $aspectValues = (_applyAspects @($resource.'.aspects') $config.aspects)
        $resource.Remove('.aspects')
        Write-Debug "Applying $($aspectValues.Keys.Count) aspect keys to $($resource.Keys.Count) resource keys."
        #Write-Debug (ConvertTo-Json $aspectValues)
        $aspectValues.Keys | Where-Object { $_ -ne '.aspects' } | Sort-Object -Unique | ForEach-Object {
            if (-not $resource.ContainsKey($_) `
                    -and $null -eq $aspectValues[$_]) {
                Write-Warning "Resource '$key' was expected to override aspect value '$_'."
            }
            elseif ($resource[$_] -is [hashtable]) {
                Write-Debug "Merging aspect value '$_'."
                $resource[$_] = (_applyStructure $resource[$_] $aspectValues[$_] $true $true)
            }
            elseif ($null -eq $resource[$_]) {
                Write-Debug "Applying aspect value '$_'."
                $resource[$_] = $aspectValues[$_]
            }
        }
    }

    return $config.resources
}
Export-ModuleMember -Function Resolve-JercResources

# Applies a set of aspects to an existing or new dictionary
function _applyAspects([string[]]$aspectsToApply, [Hashtable]$aspects, [Hashtable]$result = @{}) {
    if ($aspects.ContainsKey('*')) {
        $aspectsToApply = (@('*') + $aspectsToApply)
    }
    
    $aspectsToApply | Where-Object { $_ } | ForEach-Object {
        Write-Debug "Applying aspect '$_'."
        if (-not $aspects.ContainsKey($_)) {
            Write-Warning "Reference to unknown aspect '$_'."
            return
        }
        if (-not $aspects[$_] -is [Hashtable]) {
            Write-Warning "Reference to invalid aspect '$_'."
            return
        }

        Write-Debug "  Keys before '$_': $($result.Keys.Count)"
        if ($aspects[$_].ContainsKey('.aspects')) {
            $result = (_applyAspects $aspects[$_]['.aspects'] $aspects $result)
        }

        $result = (_applyStructure $result $aspects[$_] $true $true)
        Write-Debug "  Keys after '$_': $($result.Keys.Count)"
        #Write-Debug (ConvertTo-Json $result)
    }

    return $result
}