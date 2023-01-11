<#
.SYNOPSIS
Returns Jerc file structure with all files included.

.DESCRIPTION
Resolves Jerc file(s) to single file structure.
Returns a structure containing a single list of aspects and a single list of resources.
Jerc templates will not be transformed.

This command is intended for use in diagnosing unexpected configuration values.
For actual use of Jerc resources, see the Get-JercResources command.

.PARAMETER File
The Jerc file (JSON) to be processed.

.EXAMPLE
Resolve-JercFiles './resources.jsonc'

.LINK
Get-JercResources

.LINK
Implementation information: https://github.com/neoftl/jerc-pwsh
#>
function Resolve-JercFiles ([IO.FileInfo]$File) {
    Write-Debug "Resolving $($File.FullName)"

    if (-not $File.Exists) {
        Write-Error "Could not find configuration file '$($File.FullName)'."
        return $null
    }

    $json = (Get-Content $File.FullName -Raw)
    $config = (ConvertFrom-Json $json -AsHashtable)
    if (-not $inc -is [Hashtable]) {
        Write-Warning "Configuration file is not valid JSON '$($File.FullName)'."
        return
    }
    if (-not $config.ContainsKey('aspects')) {
        $config.Add('aspects', [Hashtable]::new()) | Out-Null
    }
    if (-not $config.ContainsKey('resources')) {
        $config.Add('resources', [Hashtable]::new()) | Out-Null
    }

    # Resolve includes
    if ($config.'.include') {
        @($config.'.include') | ForEach-Object {
            $path = [IO.Path]::Combine($File.DirectoryName, $_)
            $inc = (Resolve-JercFiles $path)
            if (-not $inc -is [Hashtable]) {
                Write-Warning "Included invalid JSON file '$path'."
                return
            }
            if ($inc) {
                if ($inc.ContainsKey('aspects')) {
                    (_applyStructure $config.aspects $inc.aspects)
                }
                if ($inc.ContainsKey('resources')) {
                    (_applyStructure $config.resources $inc.resources)
                }
            }
        }
        $config.Remove('.include')
    }

    return $config
}
Export-ModuleMember -Function Resolve-JercFiles

# Applies keys from 'new' dictionary on to 'base'
function _applyStructure([Hashtable]$base, [Hashtable]$new, [bool]$allowOverride = $false) {
    $new.Keys | Where-Object { $_ -and $_ -ne '.include' } | ForEach-Object {
        $val = $new[$_]
        if ($_ -eq '.aspects' -and $base[$_] -is [Array]) {
            $list = [Collections.ArrayList]@($base[$_])
            $list.AddRange(@($val))
            $base[$_] = $list
            return
        }

        Write-Debug "Applying key '$_'."
        if ($base.ContainsKey($_)) {
            if ($val -is [Hashtable]) {
                (_applyStructure $base[$_] $val)
            }
            elseif ($null -eq $base[$_]) {
                $base[$_] = $val
            }
            elseif ($allowOverride -and $null -ne $val) {
                $base[$_] = $val
            }
        }
        else {
            $base.Add($_, $val) | Out-Null
        }
    }
}