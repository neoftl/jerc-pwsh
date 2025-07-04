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

})