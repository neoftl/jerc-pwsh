#
# Aspect tests
#

(&$PwshTest.RunSuite 'Aspects' {
    Test-JercParser 'A001' 'Resource is resolved' '{
        "resources": { "Test": { "Actual": "One" } }
    }' 'One'
    Test-JercParser 'A002' 'Global aspect always included' '{
        "aspects": { "*": { "Actual": "One" } },
        "resources": { "Test": { } }
    }' 'One'
    Test-JercParser 'A003' 'Resource can include aspect' '{
        "aspects": { "One": { "Actual": "One" } },
        "resources": { "Test": { ".aspects": [ "One" ] } }
    }' 'One'
    Test-JercParser 'A004' 'Resource must override aspect null or warning' '{
        "aspects": { "One": { "Actual": null } },
        "resources": { "Test": { ".aspects": [ "One" ], "ExpectedWarning": "Resource 'Test' was expected to override aspect value 'Actual'." } }
    }' '' -enabled 0
    Test-JercParser 'A005' 'Resource can take overlapping aspects' '{
        "aspects": { "One": { "Actual": "One" }, "Two": { "Actual": "Two" } },
        "resources": { "Test": { ".aspects": [ "One", "Two" ] } }
    }' 'One'
    Test-JercParser 'A006' 'Resource can inherit null aspect value' '{
        "aspects": { "One": { "Actual": "{!}null" }, "Two": { "Actual": "Two" } },
        "resources": { "Test": { ".aspects": [ "One", "Two" ] } }
    }' $null
    Test-JercParser 'A007' 'Resource value overrides aspect' '{
        "aspects": { "One": { "Actual": "One" } },
        "resources": { "Test": { ".aspects": [ "One" ], "Actual": "Resource" } }
    }' 'Resource'
    Test-JercParser 'A008' 'Resource can take aspect value' '{
        "aspects": { "One": { "Actual": "One" } },
        "resources": { "Test": { ".aspects": [ "One" ], "Actual": null } }
    }' 'One'
    Test-JercParser 'A009' 'Resource can take aspect null without warning' '{
        "aspects": { "One": { "Actual": null } },
        "resources": { "Test": { ".aspects": [ "One" ], "Actual": null } }
    }' $null
    Test-JercParser 'A010' 'Aspect can include aspect' '{
        "aspects": { "One": { ".aspects": [ "Two" ] }, "Two": { "Actual": "Two" } },
        "resources": { "Test": { ".aspects": [ "One" ] } }
    }' 'Two'
    Test-JercParser 'A011' 'Aspect can override aspect value' '{
        "aspects": { "One": { ".aspects": [ "Two" ], "Actual": "One" }, "Two": { "Actual": "Two" } },
        "resources": { "Test": { ".aspects": [ "One" ] } }
    }' 'One'
    Test-JercParser 'A012' 'Aspect can accept aspect value' '{
        "aspects": { "One": { ".aspects": [ "Two" ], "Actual": null }, "Two": { "Actual": "Two" } },
        "resources": { "Test": { ".aspects": [ "One" ] } }
    }' 'Two'
    Test-JercParser 'A013' 'Aspect can remove aspect value' '{
        "aspects": { "One": { ".aspects": [ "Two" ], "Actual": "{!}null" }, "Two": { "Actual": "Two" } },
        "resources": { "Test": { ".aspects": [ "One" ] } }
    }' $null
    Test-JercParser 'A014' 'Aspect missing warning' '{
        "aspects": { },
        "resources": { "Test": { ".aspects": [ "One" ], "ExpectedWarning": "Reference to unknown aspect 'One'." } }
    }' '' -enabled 0
    Test-JercParser 'A015' 'Values only parsed once (A)' '{
        "aspects": { "One": { "Value": "{OK}" } },
        "resources": { "Test": { ".aspects": [ "One" ], "OK": "FAIL", "Actual": "{{Value}" } }
    }' '{OK}' -enabled 0
    Test-JercParser 'A016' 'Values only parsed once (B)' '{
        "aspects": { "One": { "Value": "{{OK}" } },
        "resources": { "Test": { ".aspects": [ "One" ], "OK": "FAIL", "Actual": "{Value}" } }
    }' '{OK}' -enabled 0
    Test-JercParser 'A017' 'Resource can inherit literal null aspect value' '{
        "aspects": { "One": { "Actual": "{null}" }, "Two": { "Actual": "Two" } },
        "resources": { "Test": { ".aspects": [ "One", "Two" ] } }
    }' $null
    Test-JercParser 'A018' 'Global aspect value can be overridden' '{
        "aspects": { "*": { "Actual": "One" }, "Two": { "Actual": "Two" } },
        "resources": { "Test": { ".aspects": [ "Two" ] } }
    }' 'Two'
    Test-JercParser 'A019' 'Global aspect object can be overridden' '{
        "aspects": { "*": { "Actual": { "Value": "One" } }, "Two": { "Actual": { "Value": "Two" } } },
        "resources": { "Test": { ".aspects": [ "Two" ] } }
    }' '{"Value":"Two"}'
})