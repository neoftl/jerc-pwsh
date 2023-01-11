#
# Substring tests
#

(&$PwshTest.RunSuite 'Functions' {

    Test-JercParser 'S001' 'Substrings' '{
        "resources": { "Test": { "Value": "ABCDEFG", "Actual": "{Value[,3]}/{Value[2,3]}/{Value[4]}" } }
    }' 'ABC/CDE/EFG'
    Test-JercParser 'S002' 'Substrings from end' '{
        "resources": { "Test": { "Value": "ABCDEFG", "Actual": "{Value[-4,3]}" } }
    }' 'DEF'
    Test-JercParser 'S003' 'Substrings function arg' '{
        "resources": { "Test": { "Value": "ABCDEFG", "Actual": "{LC:Value[2,3]}" } }
    }' 'cde'
    Test-JercParser 'S004' 'Substrings function result' '{
        "resources": { "Test": { "Value": "ABCDEFG", "Actual": "{:{LC:Value[1]}[2,3]}" } }
    }' 'def'

})