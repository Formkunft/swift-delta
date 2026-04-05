# ``Delta::Delta``

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
- ``subscript(_:)-8cq40``

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

- ``compose(with:)-iytf``
- ``compose(with:)-5uwg4``

### Mapping

- ``map(_:)``
- ``mapAny(_:)``
- ``mapAll(_:)``
- ``asyncMap(_:)``
- ``asyncMapAny(_:)``
- ``asyncMapAll(_:)``
- ``compacted()``
- ``withIntermediate(_:process:)``

### Identity Delta

- ``identity(_:)``
- ``isIdentity()``
- ``isIdentity(by:)``

### RandomAccessCollection 

- ``isEmpty``
- ``count``

## Coding

A delta is encoded as a keyed container with `"a"` (source) and `"b"` (target) keys:

- A source delta is encoded as `{"a": <element>}`.
- A target delta is encoded as `{"b": <element>}`.
- A pair delta is encoded as `{"a": <element>, "b": <element>}`.
