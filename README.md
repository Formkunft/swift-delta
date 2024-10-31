# LightTableDelta

A Swift package for a type `Delta<Element>` with three cases:

- `source(Element)`
- `target(Element)`
- `transition(source: Element, target: Element)`

## Description

This `Delta` type represents an inclusive OR relation: Either a source element is available, or a target element is available, or both are available.
`Delta` behaves similar to `Optional`, but instead of representing 0 or 1 elements, it represents 1 or 2 elements.

## Implementation

The source and target are described as the two sides of a delta.
Both sides are accessible via optional `source` and `target` properties.
Convenient methods like `resolve(favoring:)` and `merge(coalesce:)` also provide access to the elements.

Transform a `Delta` value to a different `Delta` value using `map(:)`, `asyncMap(:)`, `mapAny(:)`, or `mapAll(:)`.

The `Delta` type also conforms to all standard protocols (depending on the conformances of it’s `Element` type):

- `Equatable`
- `Hashable`
- `CustomDebugStringConvertible`
- `Encodable`
- `EncodableWithConfiguration`
- `Decodable`
- `DecodableWithConfiguration`
- `Sendable`
- `BitwiseCopyable`
- `~Copyable`
