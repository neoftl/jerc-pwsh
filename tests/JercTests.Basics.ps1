#
# Basic parsing tests
#

Test-JercParser 'True literal' '{
    "resources": { "Test": { "Value": "1234", "Actual": "{!}{Value}" } }
}' 1234
Test-JercParser 'End brace' '{
    "resources": { "Test": { "Value": 1234, "Actual": "Value{" } }
}' 'Value{'
Test-JercParser 'Dynamic value' '{
    "resources": { "Test": { "Value": 1234, "Actual": "[{Value}]" } }
}' '[1234]'
Test-JercParser 'Unknown key' '{
    "resources": { "Test": { "Actual": "[{Value}]" } }
}' '[]'
Test-JercParser 'Escaped braces' '{
    "resources": { "Test": { "Actual": "[{{Value}]" } }
}' '[{Value}]'
Test-JercParser 'Multiple dynamic values' '{
    "resources": { "Test": { "Value": 1234, "Actual": "{Value}{Value}{Value}" } }
}' '123412341234'
Test-JercParser 'Recursion' '{
    "resources": { "Test": { "Actual": "{Value1}::{Value2}", "Value1": 123, "Value2": "{Value1[2,1]}{Value1[1,1]}{Value1[0,1]}" } }
}' '123::321'
Test-JercParser 'Booleans are lowercase' '{
    "resources": { "Test": { "Actual": "{True}::{False}", "True": true, "False": false } }
}' 'true::false'
Test-JercParser 'Supports object content' '{
    "resources": { "Test": { "Actual": { "SubKey": "Value" } } }
}' "{ ""SubKey"": ""Value"" }"