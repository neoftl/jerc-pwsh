#
# Template transformation tests
#

Test-JercTransformer 'Basic' @{
    "Value" = "value";
} '[${Value}]' '[value]'
Test-JercTransformer 'Doesn''t auto-escape' @{
    "Value" = "value";
} '[$${Value}]' '[$value]'
Test-JercTransformer 'Can escape template' @{
    "Value" = "value";
} '[${{Value}]' '[${Value}]'
Test-JercTransformer 'JSON' @{
    "Value" = "value";
} '{ "Key": "${Value}" }' '{ "Key": "value" }'
Test-JercTransformer 'JSON structural' @{
    "Key" = "`"key`"";
} '{ ${Key}: "Value" }' '{ "key": "Value" }'
Test-JercTransformer 'JSON with logic' @{
    "Value" = "value";
} '{ "Key": ${?:Value;"{Value}";null} }' '{ "Key": "value" }'
Test-JercTransformer 'JSON many' @{
    "Value" = "value";
} '{ "Key1": "${?:Value;Yes}", "Key2": "${?:Value;;No}", "Key3": "${Value[,3]}" }' '{ "Key1": "Yes", "Key2": "", "Key3": "val" }'
Test-JercTransformer 'JSON multiline' @{
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
Test-JercTransformer 'Must not parse twice' @{
    "OK" = "FAIL";
    "Value" = "{{OK}";
} '[${Value}]' '[{OK}]'
Test-JercTransformer 'Outputs non-primative values' @{
    "Value" = @{ "A" = 123 }
} '[${Value}]' '[{
  "A": 123
}]'