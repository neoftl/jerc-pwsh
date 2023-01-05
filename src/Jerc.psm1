#
# JERC-PWSH
# https://github.com/neoftl/jerc-pwsh
#
# Powershell Core 7+ implementation of Json Extensible Resource Configuration v1.0
# https://github.com/neoftl/jerc-pwsh/blob/main/standard/spec.md
#

if (-not $PSVersionTable -or $PSVersionTable.PSVersion -lt 7) {
    Write-Error "JSON Configuration Parser v2 requires Powershell Core 7. You currently have Powershell $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion). Please upgrade."
    return
}

. $PSScriptRoot/_functions.ps1
. $PSScriptRoot/_StringBuilder.ps1

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

<#
.SYNOPSIS
Returns Jerc file structure with aspects resolved.

.DESCRIPTION
Resolves Jerc file(s) and resource aspects (if any).
Returns a dictionary of resource names, with each a dictionary of key-values.
Jerc templates will not be transformed.

This command is intended for use in diagnosing unexpected configuration values.
For actual use of Jerc resources, see the Get-JercResources command.

.PARAMETER File
The Jerc file (JSON) to be processed.

.EXAMPLE
Resolve-JercResources './resources.jsonc'

.LINK
Get-JercResources

.LINK
Implementation information: https://github.com/neoftl/jerc-pwsh
#>
function Resolve-JercResources ([IO.FileInfo]$File) {
    $config = (Resolve-JercFiles $File)

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

<#
.SYNOPSIS
Returns a text with all Jerc templates resolved for the given resource.

.DESCRIPTION
Resolves all Jerc templates in arbitrary text, based on the given resource values.

.PARAMETER Text
The text to resolve Jerc templates in.

.PARAMETER Resource
The dictionary of resource values to use in resolving templates.

.PARAMETER TemplateStart
An optional additional identifier for Jerc templates, if the standard would conflict with the text format.

.EXAMPLE
Get-Content 'MyTemplate.json' | Convert-JercTemplate -Resource $resourceValues -TemplateStart '$'

.LINK
Implementation information: https://github.com/neoftl/jerc-pwsh
#>
function Convert-JercTemplate ([Parameter(ValueFromPipeline = $true)][string]$Text, [Hashtable]$Resource, [string]$TemplateStart = '$') {
    if (-not $Text) { return '' }
    $rem = [Text.StringBuilder]$Text

    function resolveKeyName() {
        $keyName = (readArg $false)
        if (-not $keyName) {
            $result = "$rem"
            $rem.Clear() | Out-Null
            return $result
        }
            
        $value = $Resource[$keyName]
        if ($value -is [Boolean]) { $value = $value ? "true" : "false" }
        $result = (Convert-JercTemplate "$value" $Resource '')

        if ($rem[0] -eq '[') {
            $result = (doSubstring $result)
        }
        if ($rem[0] -in ';', '}') {
            $rem.Remove(0, 1) | Out-Null
        }

        return $result
    }
    function doSubstring([string]$value) {
        # "[" #? ( "," # )? "]"
        if ($rem[0] -eq '[') {
            $idx = (_indexOf $rem ']')
            if ($idx -le 0) {
                return $value
            }

            $text = (_substring $rem 0 ($idx + 1))
            if ($text -match '^\[(?:(?<S>\-?\d+)|,(?<L>\-?\d+)|(?<S>\-?\d+),(?<L>\d+))\]$') {
                $rem.Remove(0, $Matches[0].Length) | Out-Null
                $value = "$value"
                $s = [int]$Matches.S -lt 0 ? [int]$Matches.S + $value.Length : $Matches.S
                $l = [Math]::Max(0, [Math]::Min($Matches.L ? $Matches.L : $value.Length, $value.Length - $s))
                $value = $value.Substring($s, $l)
            }
        }
        return $value
    }
    function readArg([bool]$fn = $true) {
        $xChars = $fn ? @(';') : @(';', '[')
        $depth = 0
        $idx = -1
        while ($depth -ge 0) {
            $idx = (_indexOfAny $rem (@('{', '}') + $xChars) ($idx -ge 0 ? $idx + 1 : 0))
            if ($idx -lt 0) {
                $idx = $rem.Length
                break
            }
            if ($rem[$idx] -eq '{') {
                if ($rem[$idx + 1] -eq '{') {
                    $idx += 1
                }
                elseif ($rem[$idx + 1] -in $xChars -and $rem[$idx + 1] -eq '}') {
                    $idx += 2
                }
                else {
                    $depth += 1
                }
            }
            elseif ($rem[$idx] -in $xChars -and $depth -eq 0) {
                $depth = $fn ? -1 : 0
                break
            }
            elseif ($rem[$idx] -eq '}') {
                if ($depth -eq 0) {
                    break
                }
                $depth -= 1
            }
        }

        $result = $idx -gt 0 ? (_substring $rem 0 $idx) : $null
        if ($idx -ge $rem.Length - 1) {
            $rem.Clear() | Out-Null
        } else {
            $rem.Remove(0, $idx - $depth) | Out-Null
        }
        return $result
    }

    # literal* '{' ( functionName ";" )? keyName ( '[' # (( '..' # ))? ']' )? ( ";" functionArg )* '}'
    function nextSymbol() {
        # Short-cut literal
        $idx = (_indexOf $rem '{')
        if ($idx -lt 0 -or $idx -ge $rem.Length - 1) {
            $idx = $rem.Length - 1
        }
        if ($idx -gt 0) {
            $result = (_substring $rem 0 $idx)
            $rem.Remove(0, $idx) | Out-Null
            return $result
        }
        
        # "{{" - Literal brace
        if ($rem[1] -eq '{') {
            $rem.Remove(0, 2) | Out-Null
            return '{'
        }
    
        # "{;}" - Literal semicolon
        if ($rem.Length -gt 2 -and (_substring $rem 0 3) -eq '{;}') {
            $rem.Remove(0, 3) | Out-Null
            return ';'
        }
        
        # "{!}" - Literal value
        if ($rem.Length -gt 2 -and (_substring $rem 0 3) -eq '{!}') {
            $rem.Remove(0, 3) | Out-Null
            return '{!}'
        }
        
        # Check for function
        $fn = $null
        $idx = (_indexOfAny $rem @(':', '}'))
        if ($idx -gt 0 -and $rem[$idx] -eq ':') {
            $fn = (_substring $rem 1 ($idx - 1))
            $rem.Remove(0, $idx + 1) | Out-Null
            if (-not $_functions.ContainsKey($fn)) {
                Write-Warning "[ConfigurationParser] Unknown function '$fn' referenced in template."
                $rem.Clear() | Out-Null
                return $null
            }
            
            if ($rem[0] -eq '{') {
                $rem.Remove(0, 1) | Out-Null
                $arg = (readArg)
                $rem.Remove(0, 1) | Out-Null
                $value = (Convert-JercTemplate "{$arg}" $Resource '')
                $value = (doSubstring $value)
            }
            else {
                $value = (resolveKeyName)
            }
            $result = (&$_functions[$fn] $value $rem)
            $result = (Convert-JercTemplate $result $Resource '')

            if ($rem[0] -eq '}') {
                $rem.Remove(0, 1) | Out-Null
            }
        }
        else {
            # KeyName
            $rem.Remove(0, 1) | Out-Null
            $result = (resolveKeyName)
        }

        return $result
    }

    $result = ''
    while ($rem.Length) {
        # Jump to next template
        $idx = (_indexOf $rem ("$TemplateStart{"))
        if ($idx -lt 0 -or $idx -ge $rem.Length - $TemplateStart.Length - 1) {
            return "$result$rem"
        }

        # Parse template
        $result += (_substring $rem 0 $idx)
        $rem.Remove(0, $idx + $TemplateStart.Length) | Out-Null
        $value = (nextSymbol)
        $result = "$result$value"
    }
    return $result
}
Export-ModuleMember -Function Convert-JercTemplate

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
            elseif ($allowOverride -and $null -ne $val) {
                $base[$_] = $val
            }
        }
        else {
            $base.Add($_, $val) | Out-Null
        }
    }
}