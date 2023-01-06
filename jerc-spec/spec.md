# Json Extensible Resource Configuration
>This document covers the specification detail for JERC `v1.0 (Jan 2023)`.

An open-source specification of an extensible format for creating resource configurations for any purpose.

## Goals
1. Simple format for creating configuration files for any type of resource (valid JSON)
2. Hierarchy of reusable and componentised configuration files and values that is easy to trace
3. Simple language for using logic to resolve dynamic configuration values

## Usage life-cycle
1. Define resource configuration files
2. Process configuration files in to dictionary of key-values per resource
3. (Out of scope of specification) Use result structures in target processes

## Implementation requirements
Every implementation of the specification must meet the following criteria:
1. Support comments in processed JSON files ("jsonc")
2. Provide a mechanism to report warnings raised during processing

## Suggested implementation API
The minimum API of an implementation of the specification should provide:
* A method that takes a single file path and returns a dictionary of all resources with the resultant configured key-values

Additional methods that make it easier for a consumer to locate issues in their files could include a way to output the state at each of the steps when processing a configuration file:
1. The list of all files that will be processed
2. The resolved aspects and resources from all included files
3. The resolved list of resources after applying aspects (before transformations)

## Concepts
The rest of the specification makes reference to certain internal concepts:
* **Aspect:** A named set of configuration values that can be applied to a resource
* **Include:** A reference to another configuration file to be included as part of the processing
* **Resource:** A named set of configuration values that will be returned after processing
* **Template:** A piece of logic that will be transformed after processing to resolve its value

## Processing steps
The implementation of the specification expects a configuration file to be processed in the following order:
1. Resolve all included files (aspects and resources)
2. Resolve all aspects (include other aspects)
3. Apply aspects to resources
4. Warn on unprovided values (a `null` value that is not explicitly defined in the resource)
5. Transform all templates
6. Return all resources

### Key-value priority
1. Resources are included in file order.
   1. Keys are only taken if undefined or `null`.
2. Aspects are included in reference order.
   1. Keys are only taken if undefined or `null`.

To force a `null` in to a resource value, use the `"{!}null"` [template](templates.md).

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