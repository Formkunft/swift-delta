# LightTableDelta

A Swift package for a type `Delta<Element>` with three cases:

- `source(Element)`
- `target(Element)`
- `transition(source: Element, target: Element)`

## Description

This `Delta` represents an inclusive OR relation: Either a source element is available, or a target element is available, or both are available.
`Delta` behaves similar to `Optional`, but instead of representing 0 or 1 elements, it represents 1 or 2 elements.
An alternative name for this type in some other languages is `These`.

## Implementation

The source and target are described as the two sides of a delta.
Both sides are accessible via optional `source` and `target` properties.
Convenient methods like `resolve(favoring:)` and `merge(coalesce:)` also provide access to the elements.

Transform a `Delta` value to a different `Delta` value using `map(:)` or `asyncMap(:)`.

`Delta` works well when working with optionals, providing initializers to create a `Delta` from optionals as well as alternative methods like `flatMap(:)`, `compactMap(:)`, and `compactMerge(coalesce:)` to produce optionals.

The `Delta` type also conforms to all standard protocols (depending on the conformances of it’s `Element` type):

- `Equatable`
- `Hashable`
- `Encodable`
- `Decodable`
- `Sendable`
- `BitwiseCopyable`
- `~Copyable`
