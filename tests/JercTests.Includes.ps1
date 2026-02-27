#
# File inclusion tests
#

(&$PwshTest.RunSuite 'Includes' {

    # Resource
    Test-JercParser 'I001' 'New resource is included' -json1 '{
        ".include": [ "file2.json" ]
    }'  -json2 '{
        "resources": { "Test": { "Actual": "OK" } }
    }'  -Expected "OK"
    Test-JercParser 'I002' 'Resource collision: New keys are added' -json1 '{
        ".include": [ "file2.json" ],
        "resources": { "Test": { } }
    }'  -json2 '{
        "resources": { "Test": { "Actual": "OK" } }
    }'  -Expected "OK"
    Test-JercParser 'I003' 'Resource collision: Initial values take precedence' -json1 '{
        ".include": [ "file2.json" ],
        "resources": { "Test": { "Actual": "OK" } }
    }'  -json2 '{
        "resources": { "Test": { "Actual": "Fail" } }
    }'  -Expected "OK"
    Test-JercParser 'I004' 'Resource collision: Nulls are replaced' -json1 '{
        ".include": [ "file2.json" ],
        "resources": { "Test": { "Actual": null } }
    }'  -json2 '{
        "resources": { "Test": { "Actual": "OK" } }
    }'  -Expected 'OK'
    Test-JercParser 'I005' 'Resource collision: Can force null' -json1 '{
        ".include": [ "file2.json" ],
        "resources": { "Test": { "Actual": "{!}null" } }
    }'  -json2 '{
        "resources": { "Test": { "Actual": "OK" } }
    }'  -Expected $null
    Test-JercParser 'I006' 'Resource can be removed by super' -json1 '{
        ".include": [ "file2.json" ],
        "resources": { "Test": null }
    }'  -json2 '{
        "resources": { "Test": { "Actual": "OK" } }
    }'  -Expected "Missing 'Test' resource."

    # Aspects
    Test-JercParser 'I100' 'New aspect is included' -json1 '{
        ".include": [ "file2.json" ],
        "resources": { "Test": { ".aspects": [ "Test" ], "Actual": null } }
    }'  -json2 '{
        "aspects": { "Test": { "Actual": "OK" } }
    }'  -Expected "OK"
    Test-JercParser 'I101' 'Aspect collision: New keys are added' -json1 '{
        ".include": [ "file2.json" ],
        "aspects": { "Test": { } },
        "resources": { "Test": { ".aspects": [ "Test" ], "Actual": null } }
    }'  -json2 '{
        "aspects": { "Test": { "Actual": "OK" } }
    }'  -Expected "OK"
    Test-JercParser 'I102' 'Aspect collision: Initial values take precedence' -json1 '{
        ".include": [ "file2.json" ],
        "aspects": { "Test": { "Actual": "OK" } },
        "resources": { "Test": { ".aspects": [ "Test" ], "Actual": null } }
    }'  -json2 '{
        "aspects": { "Test": { "Actual": "Fail" } }
    }'  -Expected "OK"
    Test-JercParser 'I103' 'Aspect collision: Nulls are replaced' -json1 '{
        ".include": [ "file2.json" ],
        "aspects": { "Test": { "Actual": null } },
        "resources": { "Test": { ".aspects": [ "Test" ], "Actual": null } }
    }'  -json2 '{
        "aspects": { "Test": { "Actual": "OK" } }
    }'  -Expected 'OK'
    Test-JercParser 'I104' 'Aspect collision: Can force null' -json1 '{
        ".include": [ "file2.json" ],
        "aspects": { "Test": { "Actual": "{!}null" } },
        "resources": { "Test": { ".aspects": [ "Test" ], "Actual": null } }
    }'  -json2 '{
        "aspects": { "Test": { "Actual": "OK" } }
    }'  -Expected $null

    # Subincludes
    Test-JercParser 'I200' 'Sub-include: aspects' -json1 '{
        "aspects": { ".include": "file2.json" },
        "resources": { "Test": { ".aspects": "ATest", "Actual": "OK" } }
    }'  -json2 '{
        "ATest": { "Actual": "OK" }
    }'  -Expected 'OK'
    Test-JercParser 'I201' 'Sub-include: resources' -json1 '{
        "resources": { ".include": "file2.json" }
    }'  -json2 '{
        "Test": { "Actual": "OK" }
    }'  -Expected 'OK'

    # General
    Test-JercFiles 'I300' 'Wildcard includes alphabetically' -Files ([ordered]@{
        'Root' = '{ ".include": "F*.json" }' # Note: No loop protection
        'File3' = '{ "resources": { "Test": { "B": true, "C": "3" } } }'
        'File2' = '{ "resources": { "Test": { "A": true, "C": "2" } } }'
    }) -ResultLogic { param ($resources)
        return $resources.Test.A -and $resources.Test.B -and $resources.Test.C -eq '2'
    }

})