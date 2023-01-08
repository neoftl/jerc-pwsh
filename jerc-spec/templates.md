# Templates
JERC defines a simple templating language that can be used in the configuration files to produce values based on other values.

## Important notes
* Templating supports the standard JSON types: array, boolean, dictionary, null, number, string
* In boolean comparison:
  * The following values are all considered `false`:
    * `0` (number)
    * `"0"`
    * `[]` (empty array)
    * `""` (empty string)
    * `false` (boolean)
    * `"false"`
    * `null` / `undefined`
  * All other values are treated as `true`
* When converted to string, the boolean values are `true` and `false`.
* JERC attempts to keep the JSON flexibility of allowing any character in a key; however, the following characters may cause unexpected behaviour if used:
  * `{` - Definitely not supported
  * `}` - Definitely not supported
  * `[` - Must be escaped (i.e., `{[}`)
  * `;` - Must be escaped (i.e., `{;}`)
  * `!` - Cannot be used as complete key
* It is acceptable to treat string-literal equivalents of booleans and numbers as the typed value.  
e.g., `"1"` and `1` are equivalent

## Syntax
* Templates must be stored as valid string values, using `{` `}` to denote dynamic areas.
  * To place a literal `{` in a value, it should be escaped with `{{` (e.g., `"{{value}"` -> `"{value}"`).
  * A `{` without any subsequent `}` must be treated as escaped (e.g., `"{value"` -> `"{value"`).
* The most basic template is a [value](#values), using format `{` `key-name` `}`.
* [Functions](#functions) are invoked using the format `{` `fn-name` `:` `key-name` ( `;` `arg` )* `}`, where each function will specify the number of arguments required.
  * An argument is a literal or another template.
  * To include `;` within an argument value, it must be wrapped as `{;}`.
* [Substrings](#substrings) are placed at the end of `key-name` using format `key-name` `[` `start` [ `,` `length` ] `]`.
* If a string value needs to be converted to its most basic (i.e., number, boolean), a preceeding `{!}` template will mark the value as a literal.
  * Note that marking something that cannot be a literal as such must generate a warning.

### EBNF
```ebnf
template = "{", ( key-template | function-template ), "}";
key-template = key-name, [ substring-template ];
function-template = function-name, ":", key-template, { ";", fn-argument };
substring-template = "[", [ "-" ], "0-9+" (*number*), [ ",", "0-9+" (*number*) ], "]";
key-name = "..." (*any valid JSON key characters*);
function-name = "" (*NOOP*) | "?" | "??" | "LC" | "UC" | "..." (*extensible by implementations*);
fn-argument = template | "..." (*any valid characters*);
```

## Values
`{` `key-name` `}`

* `key-name` (string)
  * The literal name of the resource value to resolve.

Replaces the template with the resolved value of the `key-name` in the same resource. If the target value contains a template, that must be resolved before replacement.

Unknown keys are treated as `null`, outputting an empty value.

**Examples:**  
Given:
```
Resource
    Key1: value1
```

`"{Key1}"` -> `"value1"`  
`"{Key2}"` -> `""`

## Functions
`{` `fn-name` `:` `key-name` ( `;` `arg` )* `}`

* `fn-name` (string)
  * The literal name of the function to invoke.
  * Unknown `fn-name` references must generate a clear warning.
* `key-name` (string or template)
  * The literal name of the resource value to resolve.
  * Can include [substring](#substrings) syntax.
  * Can be a full template, if wrapped in `{` `}`, allowing for function chaining.
* `arg`* (string or template)
  * Can be a literal string value or a template.
    * Template value is only resolved if the argument value is used.
  * Zero or more arguments, separated by `;`.
  * To include `;` within an argument value, it must be wrapped as `{;}`.
  * Providing the wrong number of arguments for a function does not need to generate a warning.

The specification defines a set of minimum functions to be implemented, though implementations may provide additional functions.

### NOOP
As a special-case, the function syntax can be used to parse an inner template:
`{:` `inner-template` `}`

**Examples:**  
Given:
```
Resource
    Key1: value1
```

`"{:{?:Key1}[0,1]}"` -> `"t"`  
`"{:{?:Key2}[0,1]}"` -> `"f"`

### If: `?`
`{?:` `key-name` [ `;` `true-value` [ `;` `false-value` ] ] `}`

* With no arguments:
  * Returns the boolean equivalent of `key-name`. i.e., `"true"` or `"false"`.
* With one argument:
  * Returns `true-value` if `key-name` resolves to a `true` value, otherwise `null`.
* With two arguments:
  * Returns `true-value` if `key-name` resolves to a `true` value, otherwise the `false-value`.

**Examples:**  
Given:
```
Resource
    Key1: value1
```

`"{?:Key1;Yes}"` -> `"Yes"`  
`"{?:Key1;Yes;No}"` -> `"Yes"`  
`"{?:Key2;Yes}"` -> `""`  
`"{?:Key2;Yes;No}"` -> `"No"`

### IfNull: `??`
`{??:` `key-name` `;` `null-value` `}`

Returns the value of `key-name` if it's not `false`, otherwise returns `null-value`.

**Examples:**  
Given:
```
Resource
    Key1: value1
```

`"{??:Key1;unknown}"` -> `"value1"`  
`"{??:Key2;unknown}"` -> `"unknown"`

### Equals: `EQ`
`{EQ:` `key-name` `;` `value` `}`

Returns `true` if `key-name` resolve to `value`, otherwise `false`.

**Example:**  
Given:
```
Resource
    Key1: VALUE1
```

`"{EQ:Key1;VALUE1}"` -> `true`
`"{EQ:Key1;VALUE2}"` -> `false`

### LowerCase: `LC`
`{LC:` `key-name` `}`

* No arguments.
* Returns the value as uppercase.

**Example:**  
Given:
```
Resource
    Key1: VALUE1
```

### In set: `IN`
`{IN:` `key-name` ( `;` `value` )* `}`

Returns `true` if `key-name` resolve any `value`, otherwise `false`.

**Example:**  
Given:
```
Resource
    Key1: VALUE1
```

`"{IN:Key1;VALUE0;VALUE1;VALUE2}"` -> `true`
`"{IN:Key1;VALUE3;VALUE4}"` -> `false`

### UpperCase: `UC`
`{UC:` `key-name` `}`

* No arguments.
* Returns the value as lowercase.

**Example:**  
Given:
```
Resource
    Key1: value1
```

`"{UC:Key1}"` -> `"VALUE1"`

## Substrings
`key-name` `[` `start` [ `,` `length` ] `]`

* `start` (number)
  * If `>= 0`, the number of characters to skip from the left of the value.
  * If `< 0`, the number of characters to include from the right of the value.
* `length` (number, optional)
  * If `> 0`, the number of characters to include from `start`.