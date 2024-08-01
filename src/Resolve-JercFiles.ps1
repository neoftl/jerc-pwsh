<#
.SYNOPSIS
Returns Jerc file structure with all files included.

.DESCRIPTION
Resolves Jerc file(s) to single file structure.
Returns a structure containing a single list of aspects and a single list of resources.
Jerc templates will not be transformed.

This command is intended for use in diagnosing unexpected configuration values.
For actual use of Jerc resources, see the Get-JercResources command.

.PARAMETER Files
The Jerc files (JSON) to be processed.

.EXAMPLE
Resolve-JercFiles './resources.jsonc'

.LINK
Get-JercResources

.LINK
Implementation information: https://github.com/neoftl/jerc-pwsh
#>
function Resolve-JercFiles ([string[]]$Files) {
    $File = [IO.FileInfo]([IO.Path]::Combine($PWD, $Files[0]))
    if (-not $File.Exists) {
        Write-Error "Could not find configuration file '$($Files[0])'."
        return $null
    }

    $includes = @()
    if ($Files.Count -gt 1) {
        $includes = $Files[1..($Files.Count - 1)]
    }

    Write-Debug "Resolving $($File.FullName)"

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

    # Include additional files
    if ($includes) {
        if (-not ($config.'.include' -is [array])) {
            $config.'.include' = @()
        }
        $config.'.include' += $includes
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

        if ($base.ContainsKey($_)) {
            if ($base[$_] -is [hashtable] -and $val -is [Hashtable]) {
                Write-Debug "Applying hashtable '$_'."
                (_applyStructure $base[$_] $val $allowOverride)
            }
            elseif ($null -eq $base[$_]) {
                Write-Debug "Setting NULL key '$_' to '$val'."
                $base[$_] = $val
            }
            elseif ($allowOverride -and $null -ne $val) {
                Write-Debug "Overriding key '$_' to '$val'."
                $base[$_] = $val
            }
        }
        else {
            Write-Debug "Adding key '$_' ($($val ? $val.GetType() : 'NULL'))."
            $base.Add($_, $val) | Out-Null
        }
    }
}