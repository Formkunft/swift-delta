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

### Resolving to a Single Element

- ``resolve(favoring:)``
- ``first``
- ``last``
- ``coalesce(_:)``

### Mapping

- ``map(_:)``
- ``asyncMap(_:)``
- ``mapAny(_:)``
- ``mapAll(_:)``

### Delta Sides

- ``side``
- ``subscript(_:)-8cq40``

### Identity Delta

- ``identity(_:)``
- ``isIdentity()``
- ``isIdentity(by:)``

### RandomAccessCollection 

- ``isEmpty``
- ``count``
