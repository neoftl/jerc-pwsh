# JERC for Powershell Core
Powershell Core implementation of Json Extensible Resource Configuration v0.3-beta format.

## Specification
The JERC specification is [available here](jerc-spec/spec.md).

## Methods
**`[string] Convert-JercTemplate [string]$template, [Hashtable]$resource, [string]$templateStart = '$'`**  
Returns a text with all Jerc templates resolved for the given resource.

**`[Hashtable] Get-JercResources [string[]]$jercFiles`**  
Returns resources with fully resolved values.

**`[Hashtable] Resolve-JercFiles [string[]]$jercFiles`**  
Returns Jerc file structure with all files included.

**`[Hashtable] Resolve-JercResources [string[]]$jercFiles`**  
Returns Jerc file structure with aspects resolved.

## Usage
### Installation
(TODO: install as global module)
```pwsh
Include-Module $JercRepositoryPath/src/Jerc.psm1
```

### Resolving resources
To resolve all resources in a JERC configuration, use the `Get-JercResources` command, passing in the file path of the primary file.

```pwsh
$resources = (Get-JercResources 'resources.jsonc')
Write-Output $resources.Resource1
# Output:
# > Name     Value
# > ----     -----
# > Key1     Value1
# > Key2     Value2
```
```json
// resources.jsonc
{
    "resources": {
        "Resource1": {
            "Key1": "Value1",
            "Key2": "Value2"
        }
    }
}
```

### Transforming files
File transformation is not part of the JERC specification and is specific to `jerc-pwsh`.

The `Convert-JercTemplate` command takes the full templated string to be converted and a `Hashtable` of the resource key-values to use.  
Since this isn't part of the JERC pipeline, it can be used with any `Hashtable`.

The templated string is parsed for all standard [JERC templates](jerc-spec/templates.md), allowing for an additional identifier for templates (to prevent collision with other content). By default, this uses `$`.  
e.g., the JERC template `{Key}` must be written as `${Key}`.

By default, 

```pwsh
# Resource data (usually a resource from a Get-JercResources result, but not required)
$resource = @{
    "Key1" = "Value1"
}

# Templated string (e.g., the contents of a file)
$template = '{
    "result": "${Key1}"
}'

$result = (Convert-JercTemplate $template $resource '$')
Write-Output $result
# Output
# > {
# >     "result": "Value1"
# > }
```

### Functions
In addition to the [standard functions](jerc-spec/templates.md#functions), `jerc-pwsh` provides the following functions:

* `~`: `key-name` ( `;` `concat-arg` )*
  * Resolve the result of the `key-name` value concatented with any `concat-arg`s, as though it was a direct template
  * Example: `"{~:key}"` resolves `key` to `value` and then resolves `value` as though the template was `"{value}"`
  * Example: `"{~:key;2}"` resolves `key` to `value` and then resolves `value2` as though the template was `"{value2}"`
  * Note: If the second resolution contains escaped templates, these will be further parsed.
    * e.g., If `value` was given as `"{{key2}"`, the result will be the value of `key2`.
    * TODO: confirm

> **NOTE:** This below is currently unimplemented

* `+`: `value`; `num`
  * Add a number to a value.
  * Example: `"{+:key;1}"` adds 1 to the value of `key`
  * Note: If `key` does not resolve to a numeric value, `0` will be used.

# TODO
* Notes on how to install