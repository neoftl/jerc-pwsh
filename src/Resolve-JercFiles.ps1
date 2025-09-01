<#
.SYNOPSIS
Returns Jerc file structure with all files included.

.DESCRIPTION
Resolves Jerc file(s) to single file structure.
Returns a structure containing a single list of aspects and a single list of resources.
Jerc templates will not be transformed.

This command is intended for use in diagnosing unexpected configuration values.
For actual use of Jerc resources, see the Get-JercResources command.

.PARAMETER FilesOrHashtables
The array of Jerc files (JSON) or hashtables to be processed.

.EXAMPLE
Resolve-JercFiles './resources.jsonc'

.LINK
Get-JercResources

.LINK
Implementation information: https://github.com/neoftl/jerc-pwsh
#>
function Resolve-JercFiles ($FilesOrHashtables) {
    if ($FilesOrHashtables -isnot [array]) {
        $FilesOrHashtables = @($FilesOrHashtables)
    }

    if ($FilesOrHashtables[0] -is [hashtable]) {
        $config = [hashtable]$FilesOrHashtables[0]
    } else {
        $File = [IO.FileInfo]([IO.Path]::Combine($PWD, $FilesOrHashtables[0]))
        if (-not $File.Exists) {
            Write-Error "Could not find configuration file '$($FilesOrHashtables[0])'."
            return $null
        }

        $json = (Get-Content $File.FullName -Raw)
        $config = (ConvertFrom-Json $json -AsHashtable)
        if ($config -isnot [hashtable]) {
            Write-Warning "Configuration file is not valid JSON '$($File.FullName)'."
            return
        }
        Write-Debug "Including file $($File.FullName)"
    }

    if (-not $config.ContainsKey('aspects')) {
        $config.'aspects' = @{}
    }
    if (-not $config.ContainsKey('resources')) {
        $config.'resources' = @{}
    }
    if (-not $config.'.include') {
        $config.'.include' = @()
    }

    # Include additional items
    $includes = @($config.'.include')
    if ($FilesOrHashtables.Count -gt 1) {
        $includes += $FilesOrHashtables[1..($FilesOrHashtables.Count - 1)]
    }
    $config.Remove('.include')

    # Resolve includes
    $includes | ForEach-Object {
        $item = $_
        if ($item -isnot [hashtable]) {
            $item = [IO.Path]::Combine($File.DirectoryName, $_)
        }
        $inc = (Resolve-JercFiles $item)
        if ($inc -isnot [hashtable]) {
            Write-Warning "Included invalid JSON file '$path'."
            return
        }
        if ($inc) {
            if ($inc.ContainsKey('aspects')) {
                $config.aspects = (_applyStructure $config.aspects $inc.aspects)
            }
            if ($inc.ContainsKey('resources')) {
                $config.resources = (_applyStructure $config.resources $inc.resources)
            }
        }
    }
    @($config.resources.Keys | Where-Object { -not $_ }) | ForEach-Object {
        $config.resources.Remove($_)
    }

    return $config
}
Export-ModuleMember -Function Resolve-JercFiles

# Applies keys from 'new' dictionary on to 'base'
function _applyStructure([Hashtable]$base, [Hashtable]$new, [bool]$allowOverride = $false, [bool]$child = $false) {
    $base = $base.Clone()
    $new.Keys | Where-Object { $_ -and $_ -ne '.include' } | ForEach-Object {
        $val = $new[$_]
        if ($_ -eq '.aspects' -and $base[$_] -is [Array]) {
            $base[$_] = @($base[$_]) + @($val)
            return
        }

        if ($base.ContainsKey($_)) {
            if ($base[$_] -is [hashtable] -and $val -is [Hashtable]) {
                Write-Debug "  Applying hashtable '$_'."
                $base[$_] = (_applyStructure $base[$_] $val $allowOverride $true)
            }
            elseif ($null -eq $base[$_]) {
                if ($child) {
                    Write-Debug "  Setting NULL key '$_' to '$val'."
                    $base[$_] = $val
                } else {
                    Write-Debug "  Removing key '$_' with NULL value."
                    $base.Remove($_)
                }
            }
            elseif ($allowOverride -and $null -ne $val) {
                Write-Debug "  Overriding key '$_' to '$val'."
                $base[$_] = $val
            }
        }
        else {
            Write-Debug "  Adding key '$_' ($($val ? $val.GetType() : 'NULL'))."
            $base.Add($_, $val) | Out-Null
        }
    }
    return $base
}