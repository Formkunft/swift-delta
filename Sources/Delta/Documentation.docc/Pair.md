# ``Pair``

## Topics

### Creating a Pair

- ``init(source:target:)-(Element,Element)``
- ``init(source:target:)-(Element?,Element)``
- ``init(source:target:)-(Element,Element?)``
- ``init(source:target:)-(Element?,Element?)``
- ``init(_:)``

### Elements

- ``source``
- ``target``
- ``elements``
- ``subscript(_:)-(Delta.Side)``

### Reversing

- ``reverse()``
- ``reversed()``

### Resolving to a Single Element

- ``firstNonNilMap(_:)``
- ``lastNonNilMap(_:)``

### Composition

- ``compose(with:)-9e3af``
- ``compose(with:)-9tf58``

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

- ``identity(_:)``
- ``isIdentity()``
- ``isIdentity(by:)``

### RandomAccessCollection

- ``isEmpty``
- ``count``
