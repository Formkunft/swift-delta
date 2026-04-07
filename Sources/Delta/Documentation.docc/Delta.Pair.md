# ``Delta::Delta/Pair``

## Topics

### Creating a Pair

- ``init(source:target:)``
- ``init(source:target:)-5auek``
- ``identity(_:)``

### Elements

- ``source``
- ``target``
- ``elements``
- ``delta``
- ``subscript(_:)``

### Reversing

- ``reverse()``
- ``reversed()``

### Resolving to a Single Element

- ``firstNonNilMap(_:)``
- ``lastNonNilMap(_:)``

### Composition

- ``compose(with:)-4qzw2``
- ``compose(with:)-1ascz``

### Mapping

- ``map(_:)``
- ``mapAny(_:)``
- ``mapAll(_:)``
- ``asyncMap(_:)``
- ``asyncMapAny(_:)``
- ``asyncMapAll(_:)``
- ``compacted()``
- ``withIntermediate(_:process:)``

### Updating

- ``update(_:)-((Element)->())``
- ``update(_:)-((Element,Delta.Side)->())``

### Identity Pair

- ``isIdentity()``
- ``isIdentity(by:)``

### RandomAccessCollection

- ``isEmpty``
- ``count``

## Coding

A pair is encoded as a keyed container with `"a"` (source) and `"b"` (target) keys:

```json
{"a": <element>, "b": <element>}
```
