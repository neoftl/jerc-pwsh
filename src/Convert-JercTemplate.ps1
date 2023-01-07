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

    function str([object]$value) {
        if ($null -eq $value -or $value -is [string]) {
            return $value
        }
        return (ConvertTo-Json $value).Replace('{', '{{')
    }
    function resolveKeyName([bool]$leaveDirty = $false) {
        $keyName = (readArg $false)
        if (-not $keyName) {
            $result = "$rem"
            $rem.Clear() | Out-Null
            return $result
        }
            
        $value = $Resource[$keyName]
        if ($value -is [Boolean]) { $value = $value ? "true" : "false" }
        $result = (Convert-JercTemplate (str $value) $Resource '')

        if ($rem[0] -eq '[') {
            $result = (doSubstring $result)
        }
        if ($rem[0] -eq ';' -or (-not $leaveDirty -and $rem[0] -eq '}')) {
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
            (shift ([ref]$result) $idx)
            return $result
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
                Write-Warning "[Jerc] Unknown function '$fn' referenced in template."
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
                $value = (resolveKeyName $true)
            }
            $result = (&$_functions[$fn] $value $rem)
            $result = (Convert-JercTemplate $result $Resource '')

            while ($rem.Length -and $rem[0] -ne '}') {
                (readArg) | Out-Null
            }
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
    function shift([ref][string]$value, [int]$count, [int]$extra = 0) {
        $value.Value += (_substring $rem 0 $count)
        $rem.Remove(0, $count + $extra) | Out-Null
    }

    $result = ''
    while ($rem.Length) {
        # Jump to next template
        $idx = (_indexOf $rem ("$TemplateStart{"))
        if ($idx -lt 0 -or $idx -ge $rem.Length - $TemplateStart.Length - 1) {
            return "$result$rem"
        }
        (shift ([ref]$result) $idx)

        # Escape
        $end = $TemplateStart.Length + 1
        if ($rem[$end] -eq '{') {
            (shift ([ref]$result) $end 1)
            continue
        }

        # Parse template
        $rem.Remove(0, $TemplateStart.Length) | Out-Null
        $result += (nextSymbol)
    }
    return $result
}
Export-ModuleMember -Function Convert-JercTemplate

. $PSScriptRoot/_functions.ps1