#
# Aspect tests
#
Test-JercParser 'Resource is resolved' '{
    "resources": { "Test": { "Actual": "One" } }
}' 'One'
Test-JercParser 'Global aspect always included' '{
    "aspects": { "*": { "Actual": "One" } },
    "resources": { "Test": { } }
}' 'One'
Test-JercParser 'Resource can include aspect' '{
    "aspects": { "One": { "Actual": "One" } },
    "resources": { "Test": { ".aspects": [ "One" ] } }
}' 'One'
Test-JercParser 'Resource must override aspect null or warning' '{
    "aspects": { "One": { "Actual": null } },
    "resources": { "Test": { ".aspects": [ "One" ], "ExpectedWarning": "Resource 'Test' was expected to override aspect value 'Actual'." } }
}' '' -enabled 0
Test-JercParser 'Resource can take overlapping aspects' '{
    "aspects": { "One": { "Actual": "One" }, "Two": { "Actual": "Two" } },
    "resources": { "Test": { ".aspects": [ "One", "Two" ], "Actual": null } }
}' 'One'
Test-JercParser 'Resource can inherit null aspect value' '{
    "aspects": { "One": { "Actual": "{!}null" }, "Two": { "Actual": "Two" } },
    "resources": { "Test": { ".aspects": [ "One", "Two" ] } }
}' $null
Test-JercParser 'Resource value overrides aspect' '{
    "aspects": { "One": { "Actual": "One" } },
    "resources": { "Test": { ".aspects": [ "One" ], "Actual": "Resource" } }
}' 'Resource'
Test-JercParser 'Resource can take aspect value' '{
    "aspects": { "One": { "Actual": "One" } },
    "resources": { "Test": { ".aspects": [ "One" ], "Actual": null } }
}' 'One'
Test-JercParser 'Resource can take aspect null without warning' '{
    "aspects": { "One": { "Actual": null } },
    "resources": { "Test": { ".aspects": [ "One" ], "Actual": null } }
}' $null
Test-JercParser 'Aspect can include aspect' '{
    "aspects": { "One": { ".aspects": [ "Two" ] }, "Two": { "Actual": "Two" } },
    "resources": { "Test": { ".aspects": [ "One" ] } }
}' 'Two'
Test-JercParser 'Aspect can override aspect value' '{
    "aspects": { "One": { ".aspects": [ "Two" ], "Actual": "One" }, "Two": { "Actual": "Two" } },
    "resources": { "Test": { ".aspects": [ "One" ] } }
}' 'One'
Test-JercParser 'Aspect can accept aspect value' '{
    "aspects": { "One": { ".aspects": [ "Two" ], "Actual": null }, "Two": { "Actual": "Two" } },
    "resources": { "Test": { ".aspects": [ "One" ] } }
}' 'Two'
Test-JercParser 'Aspect can remove aspect value' '{
    "aspects": { "One": { ".aspects": [ "Two" ], "Actual": "{!}null" }, "Two": { "Actual": "Two" } },
    "resources": { "Test": { ".aspects": [ "One" ] } }
}' $null
Test-JercParser 'Aspect missing warning' '{
    "aspects": { },
    "resources": { "Test": { ".aspects": [ "One" ], "ExpectedWarning": "Reference to unknown aspect 'One'." } }
}' '' -enabled 0