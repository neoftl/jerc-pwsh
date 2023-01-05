#
# Substring tests
#

Test-JercParser 'Substrings' '{
    "resources": { "Test": { "Value": "ABCDEFG", "Actual": "{Value[,3]}/{Value[2,3]}/{Value[4]}" } }
}' 'ABC/CDE/EFG'
Test-JercParser 'Substrings from end' '{
    "resources": { "Test": { "Value": "ABCDEFG", "Actual": "{Value[-4,3]}" } }
}' 'DEF'
Test-JercParser 'Substrings function arg' '{
    "resources": { "Test": { "Value": "ABCDEFG", "Actual": "{LC:Value[2,3]}" } }
}' 'cde'
Test-JercParser 'Substrings function result' '{
    "resources": { "Test": { "Value": "ABCDEFG", "Actual": "{:{LC:Value[1]}[2,3]}" } }
}' 'def'