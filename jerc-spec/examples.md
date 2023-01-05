# Examples
This document covers working examples of what JERC will return for different configurations.

## Basic
```json
/// car.jsonc
{
    "resources": {
        "car": {
            "doors": 4,
            "wheels": 4
        }
    }
}

/// Output from processing car.jsonc
car
    doors: 4
    wheels: 4
```

## Aspect
```json
/// vehicles.jsonc
{
    "aspects": {
        "vehicle": {
            "doors": 4,
            "wheels": 4
        }
    },

    "resources": {
        "car": {
            ".aspects": [ "vehicle" ]
        },
        "truck": {
            ".aspects": [ "vehicle" ],
            "doors": 2
        }
    }
}

/// Output from processing vehicles.jsonc
car
    doors: 4
    wheels: 4
truck
    doors: 2
    wheels: 4
```

## Imported aspect
```json
/// aspects.jsonc
{
    "aspects": {
        "vehicle": {
            "doors": 4,
            "wheels": 4
        }
    }
}

/// vehicles.jsonc
{
    ".include": [ "aspects.jsonc" ],

    "resources": {
        "car": {
            ".aspects": [ "vehicle" ]
        },
        "truck": {
            ".aspects": [ "vehicle" ],
            "doors": 2
        }
    }
}

/// Output from processing vehicles.jsonc
car
    doors: 4
    wheels: 4
truck
    doors: 2
    wheels: 4
```

## Imported resource
```json
/// car.jsonc
{
    "resources": {
        "car": {
            ".aspects": [ "vehicle" ]
        }
    }
}

/// vehicles.jsonc
{
    ".include": [ "car.jsonc" ],

    "aspects": {
        "vehicle": {
            "doors": 4,
            "wheels": 4
        }
    },

    "resources": {
        "car": {
            "colour": "red"
        },
        "truck": {
            ".aspects": [ "vehicle" ],
            "doors": 2
        }
    }
}

/// Output from processing vehicles.jsonc
car
    colour: red
    doors: 4
    wheels: 4
truck
    doors: 2
    wheels: 4
```

## Dynamic value
```json
/// vehicles.jsonc
{
    "aspects": {
        "vehicle": {
            "working": true,
            "top_speed": "{?:working;100;0}"
        }
    },

    "resources": {
        "car1": {
            ".aspects": [ "vehicle" ]
        },
        "car2": {
            ".aspects": [ "vehicle" ],
            "working": false
        }
    }
}

/// Output from processing vehicles.jsonc
car1
    top_speed: 100
    working: true
car2
    top_speed: 0
    working: false
```