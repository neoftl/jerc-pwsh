#
# The Correctness tests from the spec
#

(&$PwshTest.RunSuite 'Correctness' {

    # Spec correctness test
    Test-JercResources 'C1.1' 'Correctness test 1.1' -json1 '{
        ".include": [ "file2.json" ],
        
        "aspects": {
            "Aspect2": {
                ".aspects": [ "Aspect1" ],
                "Key1": "File2.Aspect2", // Overrides File1.Aspect1
                "Key2": "File2.Aspect2", // Overrides File1.Aspect1
                "Key3": null // Supplied by File1.Aspect2
                // Key4 supplied by File1.Aspect1
            }
        },

        "resources": {
            "Resource": {
                ".aspects": [ "Aspect2" ],
                "Key2": "File2.Resource", // Overrides File2.Aspect2
                "Key5": null, // Supplied by File1.Resource
                "Key6": "File2.Resource" // Overrides File1.Resource
            }
        }
    }'  -json2 '{
        "aspects": {
            "Aspect1": {
                "Key1": "File1.Aspect1",
                "Key2": null,
                "Key4": "File1.Aspect1"
            },
            "Aspect2": {
                "Key3": "File1.Aspect2",
                "Key4": null
            }
        },

        "resources": {
            "Resource": {
                "Key5": "File1.Resource",
                "Key6": null
            }
        }
    }'  -ResultLogic { param ($resources)
        $result = $resources.Resource.Key1 -eq 'File2.Aspect2' `
            -and $resources.Resource.Key2 -eq 'File2.Resource' `
            -and $resources.Resource.Key3 -eq 'File1.Aspect2' `
            -and $resources.Resource.Key4 -eq 'File1.Aspect1' `
            -and $resources.Resource.Key5 -eq 'File1.Resource' `
            -and $resources.Resource.Key6 -eq 'File2.Resource'
        if (-not $result) {
            Write-Host (ConvertTo-Json $resources.Resource)
        }
        return $result
    }

    Test-JercFiles 'C1.2' 'Correctness test 1.2' -Files @{
        'File1' = '{ // Root
            ".include": [ "File2.json", "File3.json" ],
            "resources": {
                "Result": {
                    "Key0": null, // Must be set
                    "Key1": "File1"
                }
            }
        }'
        'File2' = '{ // Included by root
            ".include": [ "File3.json", "File4.json" ],
            "resources": {
                "Result": {
                    "Key2": "File2"
                }
            }
        }'
        'File3' = '{ // Included by root and File2
            "resources": {
                "Result": {
                    "Key0": "File3",
                    "Key3": "File3",
                    "Key2": "File3" // Does not replace
                }
            }
        }'
        'File4' = '{ // Included by File2
            "resources": {
                "Result": {
                    "Key0": "File4", // File3 has precedence
                    "Key4": "File4"
                }
            }
        }'
    } -ResultLogic { param ($resources)
        $result = $resources.Result.Key0 -eq 'File3' `
            -and $resources.Result.Key1 -eq 'File1' `
            -and $resources.Result.Key2 -eq 'File2' `
            -and $resources.Result.Key3 -eq 'File3' `
            -and $resources.Result.Key4 -eq 'File4'
        if (-not $result) {
            Write-Host (ConvertTo-Json $resources.Result)
        }
        return $result
    }
})