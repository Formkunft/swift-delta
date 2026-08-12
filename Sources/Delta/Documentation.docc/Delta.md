# ``Delta/Delta``

## Topics

### Enumeration Cases

- ``source(_:)``
- ``target(_:)``
- ``pair(source:target:)``

### Initializers

- ``init(source:target:)-(Element,Element)``
- ``init(source:target:)-(Element,Element?)``
- ``init(source:target:)-(Element?,Element)``
- ``init(source:target:)-(Element?,Element?)``

### Elements

- ``source``
- ``target``

### Delta Sides

- ``side``
- ``Delta/Side``
- ``subscript(_:)->Element?``

### Delta Pair

- ``init(_:)``
- ``Pair``

### Reversing

- ``reverse()``
- ``reversed()``

### Resolving to a Single Element

- ``first``
- ``last``
- ``resolve(favoring:)``
- ``coalesce(_:)``
- ``firstNonNilMap(_:)``
- ``lastNonNilMap(_:)``

### Composition

- ``compose(with:)-8akco``
- ``compose(with:)-3i3g8``
- ``compose(subsetting:)-6egnq``
- ``compose(subsetting:)-5cgp6``
- ``compose(subsetting:)-7y1lb``
- ``compose(subsetting:)-5tvwi``
- ``compose(intersecting:)-11kdq``
- ``compose(intersecting:)-35t8``

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

### Identity Delta

- ``identity(_:)``
- ``isIdentity()``
- ``isIdentity(by:)``

### RandomAccessCollection 

- ``isEmpty``
- ``count``
