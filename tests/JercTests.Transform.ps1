#
# Template transformation tests
#

(&$PwshTest.RunSuite 'Transforms' {

    Test-JercTransformer 'T001' 'Basic' @{
        "Value" = "value";
    } '[${Value}]' '[value]'
    Test-JercTransformer 'T002' 'Doesn''t auto-escape' @{
        "Value" = "value";
    } '[$${Value}]' '[$value]'
    Test-JercTransformer 'T003' 'Can escape template' @{
        "Value" = "value";
    } '[${{Value}]' '[${Value}]'
    Test-JercTransformer 'T004' 'JSON' @{
        "Value" = "value";
    } '{ "Key": "${Value}" }' '{ "Key": "value" }'
    Test-JercTransformer 'T005' 'JSON structural' @{
        "Key" = "`"key`"";
    } '{ ${Key}: "Value" }' '{ "key": "Value" }'
    Test-JercTransformer 'T006' 'JSON with logic' @{
        "Value" = "value";
    } '{ "Key": ${?:Value;"{Value}";null} }' '{ "Key": "value" }'
    Test-JercTransformer 'T007' 'JSON many' @{
        "Value" = "value";
    } '{ "Key1": "${?:Value;Yes}", "Key2": "${?:Value;;No}", "Key3": "${Value[,3]}" }' '{ "Key1": "Yes", "Key2": "", "Key3": "val" }'
    Test-JercTransformer 'T008' 'JSON multiline' @{
        "True" = $true;
        "Value" = 'value';
    } '{
    "Key1": "${Value}",
    "Key2": "{Literal}",
    "Key3": ${True},
    "Key4": ${?:True;false;true}
}' '{
    "Key1": "value",
    "Key2": "{Literal}",
    "Key3": true,
    "Key4": false
}'
    Test-JercTransformer 'T009' 'Must not parse twice' @{
        "OK" = "FAIL";
        "Value" = "{{OK}";
    } '[${Value}]' '[{OK}]'
    Test-JercTransformer 'T010' 'Outputs non-primative values' @{
        "Value" = @{ "A" = 123 }
    } '[${Value}]' '[{
  "A": 123
}]'
    Test-JercTransformer 'T011' 'Will fail in infinite recursion' @{
        "Value" = "{Value}";
    } '[${Value}]' '[]' -DisableWarnings

})