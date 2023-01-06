# Json Extensible Resource Configuration
>This document covers the specification detail for JERC `v0.1-beta (Jan 2023)`.

An open-source specification of an extensible format for creating resource configurations for any purpose.

## Goals
1. Simple format (valid JSON) for modeling configuration values for any type of resource.
2. Hierarchy of reusable and componentised files and values that is easy to trace.
3. Simple language for defining dynamic configuration values.

## Concepts
This specification makes reference to certain internal concepts:
* **Aspect:** A named set of configuration values that can be applied to a resource.
* **Include:** A reference to another configuration file to be included as part of the processing.
* **Resource:** A named set of configuration values that will be returned after processing.
* **Template:** A piece of logic that will be transformed after processing to resolve its value.

## Usage life-cycle
1. Create resource configuration files.
2. Process configuration files to in-memory dictionary of key-values per resource.
3. (Out of scope of specification) Use result structures in target processes.

## Implementation requirements
Every implementation of the specification must meet the following criteria:
1. Support comments in JSON files ("[jsonc](https://code.visualstudio.com/docs/languages/json#_json-with-comments)").
2. Provide a mechanism to report warnings raised during processing.
3. Support standard JSON types: array, boolean, dictionary, null, number, string.
4. Relative file paths are resolved from the current file.

## Suggested implementation API
The minimum API of an implementation of the specification should provide:
* A method that takes a single file path and returns a dictionary of all resources with the resultant configured key-values.

Additional methods that make it easier for a consumer to locate issues in their files could include a way to output the state at each of the steps when processing a configuration file:
* The list of all files that will be processed.
* The resolved aspects and resources from all included files.
* The resolved list of resources after applying aspects (before transformations).

## File structure
Every JERC file can implement the following structure:
```json
{
    // List of files to be included in to this one
    ".include": [ ... ],

    // Named resource aspects
    "aspects": {
        "aspect1": {
            ".aspects": [ ... ] // List of aspects to apply to this aspect
            // Aspect keys
        },
        ...
    },

    // Named resources
    "resources": {
        "resource`": {
            ".aspects": [ ... ] // List of aspects to apply to this resource
            // Resource keys
        },
    }
}
```

All keys are optional, and any additional keys are ignored by JERC processors.

## Processing steps
The implementation of the specification expects a configuration file to be processed in the following order:
1. Resolve all included files (merge aspects and resources).
2. Resolve all aspects (apply other aspects).
3. Apply aspects to resources.
4. Warn on unprovided values (a `null` value that is not explicitly defined in the resource).
5. Transform all templates.
6. Return all resources.

### Key-value priority
When combining sets (e.g., aspect/resource collision on include, aspect applying to aspect/resource), the value of the incoming key is only taken if:
1. the key has not been defined on the target, or
2. the key has a value of `null` on the target.

To force a `null` in to the hierarchy for a key, the `"{!}null"` [template](templates.md) will be treated like any non-`null` value until it is resolved at [step 5](#processing-steps).

**Example:**
```json
// File1.jsonc
{
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
}

// File2.jsonc
{
    ".include": [ "File1.jsonc" ],

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
}
```
```json
// After step 1
{
    "aspects": {
        "Aspect1": {
            "Key1": "File1.Aspect1", // From File1
            "Key2": null, // From File1
            "Key4": "File1.Aspect1" // From File1
        },
        "Aspect2": {
            ".aspects": [ "Aspect1" ],
            "Key1": "File2.Aspect2", // From File2
            "Key2": "File2.Aspect2", // From File2
            "Key3": "File1.Aspect2" // From File1
        }
    },

    "resources": {
        "Resource": {
            ".aspects": [ "Aspect2" ],
            "Key2": "File2.Resource", // Overrides File2.Aspect2
            "Key5": "File1.Resource", // From File1
            "Key6": "File2.Resource" // From File2
        }
    }
}
```
```json
// After step 2
{
    "aspects": {
        "Aspect1": {
            "Key1": "File1.Aspect1", // From File1
            "Key2": null, // From File1
            "Key4": "File1.Aspect1" // From File1
        },
        "Aspect2": {
            "Key1": "File2.Aspect2", // From File2
            "Key2": "File2.Aspect2", // From File2
            "Key3": "File1.Aspect2", // From File1
            "Key4": "File1.Aspect1" // From File1
        }
    },

    "resources": {
        "Resource": {
            ".aspects": [ "Aspect2" ],
            "Key2": "File2.Resource", // Overrides File2.Aspect2
            "Key5": "File1.Resource", // From File1
            "Key6": "File2.Resource" // From File2
        }
    }
}
```
```json
// After step 3
{
    "resources": {
        "Resource": {
            "Key1": "File2.Aspect2", // From File2
            "Key2": "File2.Resource", // Overrides File2.Aspect2
            "Key3": "File1.Aspect2", // From File1
            "Key4": "File1.Aspect1", // From File1
            "Key5": "File1.Resource", // From File1
            "Key6": "File2.Resource" // From File2
        }
    }
}
```

## Correctness
A suite of correctness files is included in this repository to prove the accuracy of the implementation.

## Templating
Dynamic values are resolved using the [templating language](templates.md).

# Future features under review
* Remove unused aspect key on resolve
  * e.g., "aspect": { "?key1": "value1", "?key2": "value2" } -> "resource": { ".aspects": [ "aspect" ], "a": "{key1}", "key2": null }
  * gives: "resource": { "a": "value1", "key2": "value2" }
* Deep template matching
  * e.g., "key": { "sub": "value1" } via "{key.sub}"
  * how to match "key.sub": "value2"?
  * prefer shallow over deep? alt. "{key>sub}" for deep
* Pull single value from non-included aspect
  * e.g., "{key@aspect}" matches "key" on aspect
  * escape: "{key@@aspect}" matches "key@aspect" on resource
  * Problem: aspects removed before template parsing
* Include aspect name in keys
  * e.g., ".aspects": [ "normal", "+prepended" ]
  * result A: { "key": "from-normal", "key@prepended": "from-prepended" }
  * result B: { "key": "from-normal", "prepended": { "key: "from-prepended" } } - requires deep template matching
  * Dropped from resource after processing?
* Support deep-merge of JSON value structures
* Support templates in deep-merge