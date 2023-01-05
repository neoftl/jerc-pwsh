# Available template functions
$script:_functions = @{
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
    # IfNull: value; nullValue
    '??' = { param ([string]$value)
        $nullValue = (readArg)
        if ($value -in '0', 'false') { $value = $null }
        return $value ? $value : $nullValue
    };
    # LowerCase: value
    'LC' = { param ([string]$value)
        return "$value".ToLower()
    };
    # UpperCase: value
    'UC' = { param ([string]$value)
        return "$value".ToUpper()
    };
}