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

function _combineFile([hashtable]$config, [hashtable]$inc) {
    if ($inc.aspects -is [hashtable]) {
        Write-Debug "Merging $($inc.aspects.Count) aspects"
        $config.aspects = (_applyStructure $config.aspects $inc.aspects)
    }
    if ($inc.resources -is [hashtable]) {
        Write-Debug "Merging $($inc.resources.Count) resources"
        $config.resources = (_applyStructure $config.resources $inc.resources)
    }
    return $config
}

function _resolveJercFile($path, [string]$type, [string]$dir) {
    if ($path -isnot [hashtable]) {
        $path = [IO.Path]::GetFullPath("$path", $dir)
        if ($path.Contains('*')) {
            $files = @(Get-ChildItem $path -Filter "*.json*") | Sort-Object { $_.BaseName }
            Write-Debug "Found $($files.Count) files under '$path'."
            $config = @{ }
            foreach ($file in $files) {
                $inc = (_resolveJercFile $file $type $file.DirectoryName)
                $config = (_combineFile $config $inc)
            }
            if ($type) {
                $config = $config[$type]
            }
        } else {
            $file = [IO.FileInfo]$path
            if (-not $file.Exists) {
                Write-Error "Could not find configuration file: $path"
                return @{}
            }
            $dir = $file.DirectoryName

            $config = (Get-Content $file) | ConvertFrom-Json -AsHashtable
            if ($config -is [array] -and $config.Count -gt 0 -and $null -eq $config[0]) { $config = $config[1] } # Fix issue with pre-object comments in JSONC
            if ($config -isnot [hashtable]) {
                Write-Warning "Configuration file is not a JSON object: $path"
                return @{}
            }
            Write-Debug "Including file '$path'."
        }
    }
    else {
        $config = $path
    }

    if ($type) {
        $config = @{ "$type" = $config }
    }

    # Resolve includes, relative to this file
    if (-not $config.'.include') {
        $config.'.include' = @()
    }
    foreach ($item in @($config.'.include')) {
        $inc = (_resolveJercFile $item $null $dir)
        $config = (_combineFile $config $inc)
    }
    $config.Remove('.include')

    # Include additional aspects
    if ($config.aspects -is [hashtable] -and $config.aspects.'.include') {
        foreach ($item in @($config.aspects.'.include')) {
            $inc = (_resolveJercFile $item 'aspects' $dir)
            $config = (_combineFile $config $inc)
        }
        $config.aspects.Remove('.include')
    }

    if ($config.resources -is [hashtable]) {
        # Include additional resources
        if ($config.resources.'.include') {
            foreach ($item in @($config.resources.'.include')) {
                $inc = (_resolveJercFile $item 'resources' $dir)
                $config = (_combineFile $config $inc)
            }
            $config.resources.Remove('.include')
        }

        # Remove blank keys
        @($config.resources.Keys | Where-Object { -not $_ }) | ForEach-Object {
            $config.resources.Remove($_)
        }
    }

    return $config
}

# Resolve each Jerc file and combine
function Resolve-JercFiles ($FilesOrHashtables) {
    $fileArray = @($FilesOrHashtables)
    $config = (_resolveJercFile $fileArray[0] $null $PWD)

    # Ensure structure
    if ($config.aspects -isnot [hashtable]) {
        $config.aspects = @{}
    }
    if ($config.resources -isnot [hashtable]) {
        $config.resources = @{}
    }

    # Combine all files
    if ($fileArray.Count -gt 1 ) {
        foreach ($file in $fileArray[1..($fileArray.Count - 1)]) {
            $inc = (_resolveJercFile $file $null $PWD)
            $config = (_combineFile $config $inc)
        }
    }

    # Remove blank keys
    @($config.resources.Keys | Where-Object { -not $_ }) | ForEach-Object {
        $config.resources.Remove($_)
    }

    return $config
}
Export-ModuleMember -Function Resolve-JercFiles

# Applies keys from 'new' dictionary on to 'base'
function _applyStructure([Hashtable]$base, [Hashtable]$new, [bool]$allowOverride = $false, [bool]$child = $false) {
    $base = $base ? $base.Clone() : @{}
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
                }
                else {
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