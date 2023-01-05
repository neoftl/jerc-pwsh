#
# Shim useful functionality missing from default StringBuilder
#

# IndexOf method for StringBuilder
function _indexOf([Text.StringBuilder]$sb, [string]$value) {
    $end = $sb.Length - $value.Length + 1
    $matched = 0
    for ($i = 0; $i -le $end; $i += 1) {
        if ($sb[$i] -eq $value[$matched]) {
            $matched += 1
            if ($matched -eq $value.Length) {
                return $i - $matched + 1
            }
        }
        else {
            $matched = 0
        }
    }
    return -1
}
# IndexOfAny method for StringBuilder
function _indexOfAny([Text.StringBuilder]$sb, [char[]]$chars, [int]$start = 0) {
    $end = $sb.Length
    for ($i = $start; $i -lt $end; $i += 1) {
        if ($sb[$i] -in $chars) {
            return $i
        }
    }
    return -1
}
# Substring method for StringBuilder
function _substring([Text.StringBuilder]$sb, [int]$start, [int]$length) {
    if ($length -le 0) {
        return ''
    }
    return [string]::Join('', $sb[$start..($start + $length - 1)])
}
