# Swift Delta

*Platforms: Apple OS, Linux, Android, Wasm, embedded*

Swift Delta is a package for a type `Delta<Element>` with three cases:

- `source(Element)`
- `target(Element)`
- `transition(source: Element, target: Element)`

***

- [Documentation](https://swiftpackageindex.com/Formkunft/swift-delta/documentation/deltamodule)
- [Swift Package Index](https://swiftpackageindex.com/Formkunft/swift-delta)

## Description

This `Delta` type represents an inclusive OR relation: Either a source element is available, or a target element is available, or both are available.
`Delta` behaves similar to `Optional`, but instead of representing 0 or 1 elements, it represents 1 or 2 elements.

## Implementation

The source and target are described as the two sides of a delta.
Both sides are accessible via optional `source` and `target` properties.

There are many convenient methods, including mapping a delta by transforming its elements, composing multiple deltas, coalescing a delta to a single element, and subscripting into either side of a delta.

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
- `Copyable`

Additionally, `Delta` conforms to `RandomAccessCollection`, allowing for iteration over the elements and many other operations provided by `Sequence`, `Collection`, and `BidirectionalCollection`.
