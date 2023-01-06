#
# Function tests
#

# 'If' function
Test-JercParser 'If to bool (true)' '{
    "resources": { "Test": { "Value": 1234, "Actual": "{?:Value}" } }
}' 'true'
Test-JercParser 'If to bool (false)' '{
    "resources": { "Test": { "Value": null, "Actual": "{?:Value}" } }
}' 'false'
Test-JercParser 'If (true)' '{
    "resources": { "Test": { "Value": 1234, "Actual": "{?:Value;Yes}" } }
}' 'Yes'
Test-JercParser 'If (true, variable)' '{
    "resources": { "Test": { "Value": 1234, "Actual": "{?:Value;{Value}}" } }
}' '1234'
Test-JercParser 'If (true, complex)' '{
    "resources": { "Test": { "Value": 1234, "Actual": "<{?:Value;[{Value}]}>" } }
}' '<[1234]>'
Test-JercParser 'IfElse (true, complex)' '{
    "resources": { "Test": { "Value": 1234, "Actual": "<{?:Value;[{Value}];No{;} never}> - {Value}" } }
}' '<[1234]> - 1234'
Test-JercParser 'If (missing)' '{
    "resources": { "Test": { "Actual": "{?:Value;Yes}" } }
}' ''
Test-JercParser 'If (null)' '{
    "resources": { "Test": { "Value": null, "Actual": "{?:Value;Yes}" } }
}' ''
Test-JercParser 'If (empty)' '{
    "resources": { "Test": { "Value": null, "Actual": "{?:Value;Yes}" } }
}' ''
Test-JercParser 'If (0)' '{
    "resources": { "Test": { "Value": 0, "Actual": "{?:Value;Yes}" } }
}' ''
Test-JercParser 'If (false)' '{
    "resources": { "Test": { "Value": false, "Actual": "{?:Value;Yes}" } }
}' ''
Test-JercParser 'If (false, variable)' '{
    "resources": { "Test": { "Value": false, "Actual": "{?:Value;{Value}}" } }
}' ''
Test-JercParser 'If (false, complex)' '{
    "resources": { "Test": { "Value": false, "Actual": "<{?:Value;[{Value}]}>" } }
}' '<>'
Test-JercParser 'IfElse (false, complex)' '{
    "resources": { "Test": { "Value": 0, "Actual": "<{?:Value;[{Value}];No{;} never}> - {Value}" } }
}' '<No; never> - 0'

# 'IfNull' function
Test-JercParser 'IfNull (true)' '{
    "resources": { "Test": { "Value": 1234, "Actual": "{??:Value;Yes}" } }
}' '1234'
Test-JercParser 'IfNull (false)' '{
    "resources": { "Test": { "Value": false, "Actual": "{??:Value;Yes}" } }
}' 'Yes'
Test-JercParser 'IfNull (null)' '{
    "resources": { "Test": { "Value": null, "Actual": "{??:Value;Yes}" } }
}' 'Yes'
Test-JercParser 'IfNull (0)' '{
    "resources": { "Test": { "Value": 0, "Actual": "{??:Value;Yes}" } }
}' 'Yes'
Test-JercParser 'IfNull ()' '{
    "resources": { "Test": { "Value": "", "Actual": "{??:Value;Yes}" } }
}' 'Yes'
Test-JercParser 'IfNull (JSON)' '{
    "resources": { "Test": { "Value": "", "Actual": "A{??:Value;[1,2]}Z" } }
}' 'A[1,2]Z'

# 'LowerCase' function
Test-JercParser 'LowerCase' '{
    "resources": { "Test": { "Value": "TEst", "Actual": "{LC:Value}" } }
}' 'test'

# 'UpperCase' function
Test-JercParser 'UpperCase' '{
    "resources": { "Test": { "Value": "TEst", "Actual": "{UC:Value}" } }
}' 'TEST'

# Bad function
Test-JercParser 'Unknown function warning' '{
    "resources": { "Test": { "Actual": ">{X:Test}<", "ExpectedWarning": "Reference to unknown aspect One." } }
}' '' -enabled 0
Test-JercParser 'Function must not parse keyName as template' '{
    "resources": { "Test": { "LC:Value": "TEST", "Actual": "{:LC:Value[1,2]}" } }
}' 'ES'
Test-JercParser 'Too many arguments; ignored' '{
    "resources": { "Test": { "Value": "TEST", "Actual": "{LC:Value;A;B;C}" } }
}' 'test'