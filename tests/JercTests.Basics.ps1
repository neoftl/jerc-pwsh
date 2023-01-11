#
# Basic parsing tests
#

(&$PwshTest.RunSuite 'Basics' {
    Test-JercParser 'B001' 'True literal' '{
        "resources": { "Test": { "Value": "1234", "Actual": "{!}{Value}" } }
    }' 1234
    Test-JercParser 'B002' 'End brace' '{
        "resources": { "Test": { "Value": 1234, "Actual": "Value{" } }
    }' 'Value{'
    Test-JercParser 'B003' 'Dynamic value' '{
        "resources": { "Test": { "Value": 1234, "Actual": "[{Value}]" } }
    }' '[1234]'
    Test-JercParser 'B004' 'Unknown key' '{
        "resources": { "Test": { "Actual": "[{Value}]" } }
    }' '[]'
    Test-JercParser 'B005' 'Escaped braces' '{
        "resources": { "Test": { "Actual": "[{{Value}]" } }
    }' '[{Value}]'
    Test-JercParser 'B006' 'Multiple dynamic values' '{
        "resources": { "Test": { "Value": 1234, "Actual": "{Value}{Value}{Value}" } }
    }' '123412341234'
    Test-JercParser 'B007' 'Recursion' '{
        "resources": { "Test": { "Actual": "{Value1}::{Value2}", "Value1": 123, "Value2": "{Value1[2,1]}{Value1[1,1]}{Value1[0,1]}" } }
    }' '123::321'
    Test-JercParser 'B008' 'Booleans are lowercase' '{
        "resources": { "Test": { "Actual": "{True}::{False}", "True": true, "False": false } }
    }' 'true::false'
    Test-JercParser 'B009' 'Supports object content' '{
        "resources": { "Test": { "Actual": { "SubKey": "Value" } } }
    }' "{""SubKey"":""Value""}"
})