#
# Function tests
#

(&$PwshTest.RunSuite 'Functions' {

    # 'If' function
    Test-JercParser 'F001' 'If to bool (true)' '{
        "resources": { "Test": { "Value": 1234, "Actual": "{?:Value}" } }
    }' 'true'
    Test-JercParser 'F002' 'If to bool (false)' '{
        "resources": { "Test": { "Value": null, "Actual": "{?:Value}" } }
    }' 'false'
    Test-JercParser 'F003' 'If (true)' '{
        "resources": { "Test": { "Value": 1234, "Actual": "{?:Value;Yes}" } }
    }' 'Yes'
    Test-JercParser 'F004' 'If (true, variable)' '{
        "resources": { "Test": { "Value": 1234, "Actual": "{?:Value;{Value}}" } }
    }' '1234'
    Test-JercParser 'F005' 'If (true, complex)' '{
        "resources": { "Test": { "Value": 1234, "Actual": "<{?:Value;[{Value}]}>" } }
    }' '<[1234]>'
    Test-JercParser 'F006' 'IfElse (true, complex)' '{
        "resources": { "Test": { "Value": 1234, "Actual": "<{?:Value;[{Value}];No{;} never}> - {Value}" } }
    }' '<[1234]> - 1234'
    Test-JercParser 'F007' 'If (missing)' '{
        "resources": { "Test": { "Actual": "{?:Value;Yes}" } }
    }' ''
    Test-JercParser 'F008' 'If (null)' '{
        "resources": { "Test": { "Value": null, "Actual": "{?:Value;Yes}" } }
    }' ''
    Test-JercParser 'F009' 'If (empty)' '{
        "resources": { "Test": { "Value": null, "Actual": "{?:Value;Yes}" } }
    }' ''
    Test-JercParser 'F010' 'If (0)' '{
        "resources": { "Test": { "Value": 0, "Actual": "{?:Value;Yes}" } }
    }' ''
    Test-JercParser 'F011' 'If (false)' '{
        "resources": { "Test": { "Value": false, "Actual": "{?:Value;Yes}" } }
    }' ''
    Test-JercParser 'F012' 'If (false, variable)' '{
        "resources": { "Test": { "Value": false, "Actual": "{?:Value;{Value}}" } }
    }' ''
    Test-JercParser 'F013' 'If (false, complex)' '{
        "resources": { "Test": { "Value": false, "Actual": "<{?:Value;[{Value}]}>" } }
    }' '<>'
    Test-JercParser 'F014' 'IfElse (false, complex)' '{
        "resources": { "Test": { "Value": 0, "Actual": "<{?:Value;[{Value}];No{;} never}> - {Value}" } }
    }' '<No; never> - 0'

    # 'IfNull' function
    Test-JercParser 'F100' 'IfNull (true)' '{
        "resources": { "Test": { "Value": 1234, "Actual": "{??:Value;Yes}" } }
    }' '1234'
    Test-JercParser 'F101' 'IfNull (false)' '{
        "resources": { "Test": { "Value": false, "Actual": "{??:Value;Yes}" } }
    }' 'Yes'
    Test-JercParser 'F102' 'IfNull (null)' '{
        "resources": { "Test": { "Value": null, "Actual": "{??:Value;Yes}" } }
    }' 'Yes'
    Test-JercParser 'F103' 'IfNull (0)' '{
        "resources": { "Test": { "Value": 0, "Actual": "{??:Value;Yes}" } }
    }' 'Yes'
    Test-JercParser 'F104' 'IfNull ()' '{
        "resources": { "Test": { "Value": "", "Actual": "{??:Value;Yes}" } }
    }' 'Yes'
    Test-JercParser 'F105' 'IfNull (JSON)' '{
        "resources": { "Test": { "Value": "", "Actual": "A{??:Value;[1,2]}Z" } }
    }' 'A[1,2]Z'
    Test-JercParser 'F106' 'IfNull (multi 1)' '{
        "resources": { "Test": { "Value": 1, "Actual": "{??:Value;0;0}" } }
    }' '1'
    Test-JercParser 'F106' 'IfNull (multi 2)' '{
        "resources": { "Test": { "Value": 0, "Actual": "{??:Value;2;0}" } }
    }' '2'
    Test-JercParser 'F106' 'IfNull (multi 3)' '{
        "resources": { "Test": { "Value": 0, "Actual": "{??:Value;0;3}" } }
    }' '3'

    # 'Equals' function
    Test-JercParser 'F200' 'Equals (true)' '{
        "resources": { "Test": { "Value": 1234, "Actual": "{EQ:Value;1234}" } }
    }' 'true'
    Test-JercParser 'F201' 'Equals (false)' '{
        "resources": { "Test": { "Value": 4321, "Actual": "{EQ:Value;1234}" } }
    }' 'false'
    Test-JercParser 'F202' 'Equals (sub true)' '{
        "resources": { "Test": { "Value": 1234, "Actual": "{?:{EQ:Value;1234};Yes;No}" } }
    }' 'Yes'
    Test-JercParser 'F203' 'Equals (sub false)' '{
        "resources": { "Test": { "Value": 4321, "Actual": "{?:{EQ:Value;1234};Yes;No}" } }
    }' 'No'

    # 'LowerCase' function
    Test-JercParser 'F300' 'LowerCase' '{
        "resources": { "Test": { "Value": "TEst", "Actual": "{LC:Value}" } }
    }' 'test'

    # 'In' function
    Test-JercParser 'F400' 'In (true 1)' '{
        "resources": { "Test": { "Value": "OK", "Actual": "{IN:Value;OK;A;B}" } }
    }' 'true'
    Test-JercParser 'F401' 'In (true 2)' '{
        "resources": { "Test": { "Value": "OK", "Actual": "{IN:Value;A;OK;B}" } }
    }' 'true'
    Test-JercParser 'F402' 'In (true 3)' '{
        "resources": { "Test": { "Value": "OK", "Actual": "{IN:Value;A;B;OK}" } }
    }' 'true'
    Test-JercParser 'F403' 'In (false)' '{
        "resources": { "Test": { "Value": "OK", "Actual": "{IN:Value;A;B;C}" } }
    }' 'false'

    # 'UpperCase' function
    Test-JercParser 'F500' 'UpperCase' '{
        "resources": { "Test": { "Value": "TEst", "Actual": "{UC:Value}" } }
    }' 'TEST'

    # Bad function
    Test-JercParser 'F600' 'Unknown function warning' '{
        "resources": { "Test": { "Actual": ">{X:Test}<", "ExpectedWarning": "Reference to unknown aspect One." } }
    }' '' -enabled 0
    Test-JercParser 'F601' 'Function must not parse keyName as template' '{
        "resources": { "Test": { "LC:Value": "TEST", "Actual": "{:LC:Value[1,2]}" } }
    }' 'ES'
    Test-JercParser 'F602' 'Too many arguments; ignored' '{
        "resources": { "Test": { "Value": "TEST", "Actual": "{LC:Value;A;B;C}" } }
    }' 'test'

})