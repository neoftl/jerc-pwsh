# Future features under review
* Remove unused aspect key on resolve
  * e.g., `"aspect": { "?key1": "value1", "?key2": "value2" }` -> `"resource": { ".aspects": [ "aspect" ], "a": "{key1}", "key2": null }`
  * gives: `"resource": { "a": "value1", "key2": "value2" }`
* Deep template matching
  * e.g., `"key": { "sub": "value1" }` via `"{key.sub}"`
  * how to match `"key.sub": "value2"`?
  * prefer shallow over deep? alt. `"{key>sub}"` for deep
* Pull single value from non-included aspect
  * e.g., `"{key@aspect}"` matches `"key"` on aspect
  * escape: `"{key@@aspect}"` matches `"key@aspect"` on resource
  * Problem: aspects removed before template parsing
* Include aspect name in keys
  * e.g., `".aspects": [ "normal", "+prepended" ]`
  * result A: `{ "key": "from-normal", "key@prepended": "from-prepended" }`
  * result B: `{ "key": "from-normal", "prepended": { "key: "from-prepended" } }` - requires deep template matching
  * Dropped from resource after processing?
* Support deep-merge of JSON value structures
* Support templates in deep-merge
* Post-resolution key replacement
  * After keys have been resolved, some keys are renamed to replace others
  * e.g., `{ "Key1": "value", "!Key1": "{UC:Key1}" }`
  * resolves to: `{ "Key1": "value", "!Key1": "VALUE" }`
  * result: `{ "Key1": "VALUE" }`
* Exclude keys from imported/merged blocks
  * e.g., `".exclude": [ "Key1" ]`
  * `Key1` will be ignored during collision or aspect import
* Explicit list of keys that must exist
  * e.g., `".require": [ "Key1" ]`
  * Step 4 warns for any keys in the list that do not exist (`null` is accepted)
* Only override aspect key if not defined
  * e.g., `"Resource1": { ".aspects": [ "Aspect1" ], "?Key1": "value" }`
  * Result: `Resource.Key1` will only be `"value"` if `Aspect1` doesn't supply `Key1` or it is `null`