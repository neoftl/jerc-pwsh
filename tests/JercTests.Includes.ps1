#
# File inclusion tests
#

# Resource
Test-JercParser 'New resource is included' -json1 '{
    ".include": [ "file2.json" ]
}'  -json2 '{
    "resources": { "Test": { "Actual": "OK" } }
}'  -Expected "OK"
Test-JercParser 'Resource collision: New keys are added' -json1 '{
    ".include": [ "file2.json" ],
    "resources": { "Test": { } }
}'  -json2 '{
    "resources": { "Test": { "Actual": "OK" } }
}'  -Expected "OK"
Test-JercParser 'Resource collision: Initial values take precedence' -json1 '{
    ".include": [ "file2.json" ],
    "resources": { "Test": { "Actual": "OK" } }
}'  -json2 '{
    "resources": { "Test": { "Actual": "Fail" } }
}'  -Expected "OK"
Test-JercParser 'Resource collision: Nulls are not replaced' -json1 '{
    ".include": [ "file2.json" ],
    "resources": { "Test": { "Actual": null } }
}'  -json2 '{
    "resources": { "Test": { "Actual": "OK" } }
}'  -Expected $null

# Aspects
Test-JercParser 'New aspect is included' -json1 '{
    ".include": [ "file2.json" ],
    "resources": { "Test": { ".aspects": [ "Test" ], "Actual": null } }
}'  -json2 '{
    "aspects": { "Test": { "Actual": "OK" } }
}'  -Expected "OK"
Test-JercParser 'Aspect collision: New keys are added' -json1 '{
    ".include": [ "file2.json" ],
    "aspects": { "Test": { } },
    "resources": { "Test": { ".aspects": [ "Test" ], "Actual": null } }
}'  -json2 '{
    "aspects": { "Test": { "Actual": "OK" } }
}'  -Expected "OK"
Test-JercParser 'Aspect collision: Initial values take precedence' -json1 '{
    ".include": [ "file2.json" ],
    "aspects": { "Test": { "Actual": "OK" } },
    "resources": { "Test": { ".aspects": [ "Test" ], "Actual": null } }
}'  -json2 '{
    "aspects": { "Test": { "Actual": "Fail" } }
}'  -Expected "OK"
Test-JercParser 'Aspect collision: Nulls are not replaced' -json1 '{
    ".include": [ "file2.json" ],
    "aspects": { "Test": { "Actual": null } },
    "resources": { "Test": { ".aspects": [ "Test" ], "Actual": null } }
}'  -json2 '{
    "aspects": { "Test": { "Actual": "OK" } }
}'  -Expected $null