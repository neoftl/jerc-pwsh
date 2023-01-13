<#
.SYNOPSIS
Returns Jerc file structure with aspects resolved.

.DESCRIPTION
Resolves Jerc file(s) and resource aspects (if any).
Returns a dictionary of resource names, with each a dictionary of key-values.
Jerc templates will not be transformed.

This command is intended for use in diagnosing unexpected configuration values.
For actual use of Jerc resources, see the Get-JercResources command.

.PARAMETER Files
The Jerc files (JSON) to be processed.

.EXAMPLE
Resolve-JercResources './resources.jsonc'

.LINK
Get-JercResources

.LINK
Implementation information: https://github.com/neoftl/jerc-pwsh
#>
function Resolve-JercResources ([string[]]$Files) {
    $config = (Resolve-JercFiles $Files)

    @($config.resources.Keys | Where-Object { -not $_ }) | ForEach-Object {
        $config.resources.Remove($_)
    }
    $config.resources.Keys | ForEach-Object {
        $key = $_
        $resource = $config.resources[$_]
        if (-not $resource.ContainsKey('.aspects')) {
            $resource.'.aspects' = [string[]]::new(0)
        }
        else {
            [Array]::Reverse($resource.'.aspects')
        }
        $aspectValues = (_applyAspects @($resource.'.aspects') $config.aspects)
        $resource.Remove('.aspects')
        $aspectValues.Keys | Where-Object { $_ -ne '.aspects' } | Sort-Object -Unique | ForEach-Object {
            if (-not $resource.ContainsKey($_)) {
                if ($null -eq $aspectValues[$_]) {
                    Write-Warning "Resource '$key' was expected to override aspect value '$_'."
                    return
                }
            }
            elseif ($null -ne $resource[$_]) {
                return # Keep resource value
            }
            $resource[$_] = $aspectValues[$_]
        }
    }

    return $config.resources
}
Export-ModuleMember -Function Resolve-JercResources

# Applies a set of aspects to an existing or new dictionary
function _applyAspects([string[]]$aspectsToApply, [Hashtable]$aspects, [Hashtable]$result = $null) {
    if ($null -eq $result) {
        $result = [Hashtable]::new()
    }

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

        Write-Debug "  Keys before: $($result.Keys.Count)"
        if ($aspects[$_].ContainsKey('.aspects')) {
            $result = (_applyAspects $aspects[$_]['.aspects'] $aspects $result)
        }

        (_applyStructure $result $aspects[$_] $true)
        Write-Debug "  Keys after: $($result.Keys.Count)"
    }

    return $result
}