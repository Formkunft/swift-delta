# ``DeltaModule``

A type `Delta<Element>` representing an inclusive OR relation.

The `Delta<Element>` type has three cases:

- `source(Element)`
- `target(Element)`
- `transition(source: Element, target: Element)`

This `Delta` type represents an inclusive OR relation: Either a source element is available, or a target element is available, or both are available.
`Delta` behaves similar to `Optional`, but instead of representing 0 or 1 elements, it represents 1 or 2 elements.
