# Available template functions
$script:_functions = @{
    ### Core functions

    # NOOP
    ''   = { param ([string]$value) return $value };
    # If: condition - short for "If: condition; 'true'; 'false'"
    # If: condition; trueValue
    # If: condition; trueValue; falseValue
    '?'  = { param ([string]$conditionValue)
        $trueValue = (readArg)
        $falseValue = (readArg)
        if ($null -eq $trueValue -and $null -eq $falseValue) {
            $trueValue = 'true'
            $falseValue = 'false'
        }
        if ($conditionValue -in '0', 'false') { $conditionValue = $null }
        return $conditionValue ? $trueValue : $falseValue
    };
    # IfNull: value; nullValue*
    '??' = { param ([string]$value)
        while ($rem -and $rem[0] -ne '}' -and (-not $value -or $value -in '0', 'false')) {
            $value = (readArg)
        }
        return $value
    };
    # Equals: value1; value2
    'EQ' = { param ([string]$value1)
        $value2 = (readArg)
        return $value1 -eq $value2
    };
    # LowerCase: value
    'LC' = { param ([string]$value)
        return "$value".ToLower()
    };
    # In set: value1; value2; ...
    'IN' = { param ([string]$value1)
        while ($rem[0] -and $rem[0] -ne '}') {
            $value2 = (readArg)
            if ($value2 -eq $value1) {
                return $true
            }
        }
        return $false
    };
    # NULL
    'NULL' = { param ([string]$value)
        return $null
    };
    # UpperCase: value
    'UC' = { param ([string]$value)
        return "$value".ToUpper()
    };

    ### Extension functions

    # Self-resolve: value
    '~' = { param ([string]$value)
        while ($rem[0] -and $rem[0] -ne '}') {
            $value += (readArg)
        }
        return "{:$value}"
    };
}