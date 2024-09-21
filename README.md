# LightTableDelta

A Swift package for a type `Delta<Element>` with three cases:

- `deleted(Element)`: A source element.
- `added(Element)`: A target element.
- `modified(Element, Element)`: Both source and target elements.

Such a delta value is useful to represent an inclusive OR relation for the presence of a source and a target element.
Either element (delta side) may be absent, but never both.
In other languages, this type is also known as `These`.

The type also offers useful properties for accessing either side’s element as optionals, initializing a `Delta` from optionals, and mapping methods returning transformed delta values.
