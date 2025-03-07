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
    if ($FilesOrHashtables -is [string] -or ($FilesOrHashtables -is [array] -and $FilesOrHashtables[0] -is [string])) {
        $config = [hashtable](Resolve-JercFiles $FilesOrHashtables)
    }
    elseif ($FilesOrHashtables -is [hashtable]) {
        $config = [hashtable]$FilesOrHashtables
    }
    elseif ($FilesOrHashtables -is [array] -and $FilesOrHashtables[0] -is [hashtable]) {
        $config = [hashtable]$FilesOrHashtables[0]
    }
    else {
        Write-Error "Unsupported parameter type '$(($FilesOrHashtables)?.GetType())'."
        return
    }
    if (-not $config.ContainsKey('aspects')) {
        $config.'aspects' = @{}
    }
    if (-not $config.ContainsKey('resources')) {
        $config.'resources' = @{}
    }
    if ($FilesOrHashtables -is [array]) {
        $FilesOrHashtables[1..$FilesOrHashtables.Length] | ForEach-Object {
            if ($_ -isnot [hashtable]) {
                Write-Error "Unsupported parameter type '$($_.GetType())'."
                exit
            }
            if ($_.ContainsKey('aspects')) {
                $config.aspects = (_applyStructure $config.aspects $_.aspects)
            }
            if ($_.ContainsKey('resources')) {
                $config.resources = (_applyStructure $config.resources $_.resources)
            }
        }
    }

    @($config.resources.Keys | Where-Object { -not $_ }) | ForEach-Object {
        $config.resources.Remove($_)
    }
    $config.resources.Keys | ForEach-Object {
        Write-Debug "Resolving resource '$_'."
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
        Write-Debug "Applying $($aspectValues.Keys.Count) aspect keys to $($resource.Keys.Count) resource keys."
        #Write-Debug (ConvertTo-Json $aspectValues)
        $aspectValues.Keys | Where-Object { $_ -ne '.aspects' } | Sort-Object -Unique | ForEach-Object {
            if (-not $resource.ContainsKey($_) `
                    -and $null -eq $aspectValues[$_]) {
                Write-Warning "Resource '$key' was expected to override aspect value '$_'."
            }
            elseif ($resource[$_] -is [hashtable]) {
                Write-Debug "Merging aspect value '$_'."
                $resource[$_] = (_applyStructure $resource[$_] $aspectValues[$_] $true)
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

        $result = (_applyStructure $result $aspects[$_] $true)
        Write-Debug "  Keys after '$_': $($result.Keys.Count)"
        #Write-Debug (ConvertTo-Json $result)
    }

    return $result
}