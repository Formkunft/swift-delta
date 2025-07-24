# ``Delta``

## Topics

### Enumeration Cases

- ``source(_:)``
- ``target(_:)``
- ``transition(source:target:)``

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
- ``subscript(_:)-8cq40``

### Resolving to a Single Element

- ``first``
- ``last``
- ``resolve(favoring:)``
- ``coalesce(_:)``

### Composition

- ``compose(with:)-iytf``
- ``compose(with:)-5uwg4``

### Mapping

- ``map(_:)``
- ``asyncMap(_:)``
- ``mapAny(_:)``
- ``asyncMapAny(_:)``
- ``mapAll(_:)``
- ``asyncMapAll(_:)``
- ``withIntermediate(_:process:)``

### Identity Delta

- ``identity(_:)``
- ``isIdentity()``
- ``isIdentity(by:)``

### RandomAccessCollection 

- ``isEmpty``
- ``count``
