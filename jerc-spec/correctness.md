# Correctness
This document outlines a series of examples that can be used to check the correctness of an implementation.

## 1. Including files
### 1.1. Resources
**Input:**
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

**Result:**
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