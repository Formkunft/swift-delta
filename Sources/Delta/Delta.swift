//
//  Copyright 2024 Florian Pircher
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

/// A type representing a source element, a target element, or both a source and a target element.
@frozen
public enum Delta<Element>: ~Copyable where Element: ~Copyable {
	/// The type of the elements.
	public typealias Element = Element
	
	/// A source element.
	///
	/// Conceptually, this case represents a value where the element was deleted and thus no target element is available.
	case source(Element)
	/// A target element.
	///
	/// Conceptually, this case represents a value where the element was added and thus no source element is available.
	case target(Element)
	/// The combination of a source element and a target element.
	///
	/// Conceptually, this case represents a value where an element was modified or kept the same and thus both a source and a target element are available.
	case pair(source: Element, target: Element)
}

extension Delta where Element: ~Copyable {
	/// Creates a pair delta.
	@inlinable @inline(__always)
	public init(source: consuming Element, target: consuming Element) {
		self = .pair(source: source, target: target)
	}
	
	/// Creates a target delta if `source` is `nil`; otherwise, creates a pair delta.
	@inlinable
	public init(source: consuming Element?, target: consuming Element) {
		if let source {
			self = .pair(source: source, target: target)
		}
		else {
			self = .target(target)
		}
	}
	
	/// Creates a source delta if `target` is `nil`; otherwise, creates a pair delta.
	@inlinable
	public init(source: consuming Element, target: consuming Element?) {
		if let target {
			self = .pair(source: source, target: target)
		}
		else {
			self = .source(source)
		}
	}
	
	/// Creates a delta when one or both elements are non-`nil`; otherwise, returns `nil`.
	///
	/// - If both the source and target are non-`nil`, creates a pair delta.
	/// - Else, if the source is non-`nil`, creates a source delta.
	/// - Else, if the target is non-`nil`, creates a target delta.
	/// - Otherwise, returns `nil`.
	@inlinable
	public init?(source: consuming Element?, target: consuming Element?) {
		if source != nil && target != nil {
			self = .pair(source: source!, target: target!)
		}
		else if let source {
			self = .source(source)
		}
		else if let target {
			self = .target(target)
		}
		else {
			return nil
		}
	}
}

extension Delta where Element: ~Copyable {
	/// Returns the side for source and target deltas and `nil` for pair deltas.
	@inlinable
	public var side: Side? {
		switch self {
		case .source(_): .source
		case .target(_): .target
		case .pair(source: _, target: _): nil
		}
	}
	
	/// Swaps the source and target sides of the delta in place.
	///
	/// - A source delta becomes a target delta.
	/// - A target delta becomes a source delta.
	/// - A pair delta has its source and target elements swapped.
	@inlinable
	public mutating func reverse() {
		self = (consume self).reversed()
	}
	
	/// Returns a delta with the source and target sides swapped.
	///
	/// - A source delta becomes a target delta.
	/// - A target delta becomes a source delta.
	/// - A pair delta has its source and target elements swapped.
	@inlinable
	public consuming func reversed() -> Delta {
		switch consume self {
		case .source(let element):
			.target(element)
		case .target(let element):
			.source(element)
		case .pair(let source, let target):
			.pair(source: target, target: source)
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements.
	@inlinable
	public consuming func map<E, T: ~Copyable>(
		_ transform: (consuming Element) throws(E) -> T,
	) throws(E) -> Delta<T> {
		switch consume self {
		case .source(let source):
			.source(try transform(source))
		case .target(let target):
			.target(try transform(target))
		case .pair(let source, let target):
			.pair(source: try transform(source), target: try transform(target))
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements, or `nil`, if the closure returns `nil` for all elements.
	///
	/// Instead of passing the identity function, `{ $0 }`, consider using the equivalent ``compacted()`` instead.
	@inlinable
	public consuming func mapAny<E, T: ~Copyable>(
		_ transform: (consuming Element) throws(E) -> T?,
	) throws(E) -> Delta<T>? {
		switch consume self {
		case .source(let source):
			guard let source = try transform(source) else {
				return nil
			}
			return .source(source)
		case .target(let target):
			guard let target = try transform(target) else {
				return nil
			}
			return .target(target)
		case .pair(let source, let target):
			let source = try transform(source)
			let target = try transform(target)
			
			return if let source {
				if let target {
					.pair(source: source, target: target)
				}
				else {
					.source(source)
				}
			}
			else if let target {
				.target(target)
			}
			else {
				nil
			}
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements, or `nil`, if the closure returns `nil` for any element.
	@inlinable
	public consuming func mapAll<E, T: ~Copyable>(
		_ transform: (consuming Element) throws(E) -> T?,
	) throws(E) -> Delta<T>? {
		switch consume self {
		case .source(let source):
			guard let source = try transform(source) else {
				return nil
			}
			return .source(source)
		case .target(let target):
			guard let target = try transform(target) else {
				return nil
			}
			return .target(target)
		case .pair(let source, let target):
			guard let source = try transform(source),
			      let target = try transform(target) else {
				return nil
			}
			return .pair(source: source, target: target)
		}
	}
	
	/// Removes `nil` elements from a delta with optional elements, returning `nil` if no elements remain.
	///
	/// - A source delta with a `nil` element returns `nil`.
	/// - A target delta with a `nil` element returns `nil`.
	/// - A pair delta with one `nil` element becomes a source or target delta.
	/// - A pair delta with both elements `nil` returns `nil`.
	///
	/// This is equivalent to ``mapAny(_:)`` with the identity function `{ $0 }` as its argument.
	@inlinable
	public consuming func compacted<T>() -> Delta<T>? where T? == Element {
		switch consume self {
		case .source(let source):
			guard let source else {
				return nil
			}
			return .source(source)
		case .target(let target):
			guard let target else {
				return nil
			}
			return .target(target)
		case .pair(let source, let target):
			if let source {
				if let target {
					return .pair(source: source, target: target)
				}
				else {
					return .source(source)
				}
			}
			else if let target {
				return .target(target)
			}
			else {
				return nil
			}
		}
	}
	
	/// Applies a transformation to the elements in source–target order and returns the first non-`nil` result.
	///
	/// Returns `nil` when the transformation returns `nil` for all elements.
	@inlinable
	public func firstNonNilMap<E, T: ~Copyable>(
		_ transform: (borrowing Element) throws(E) -> T?,
	) throws(E) -> T? {
		switch self {
		case .source(let element):
			try transform(element)
		case .target(let element):
			try transform(element)
		case .pair(source: let source, target: let target):
			if let result = try transform(source) {
				result
			}
			else {
				try transform(target)
			}
		}
	}
	
	/// Applies a transformation to the elements in target–source order and returns the first non-`nil` result.
	///
	/// Returns `nil` when the transformation returns `nil` for all elements.
	@inlinable
	public func lastNonNilMap<E, T: ~Copyable>(
		_ transform: (borrowing Element) throws(E) -> T?,
	) throws(E) -> T? {
		switch self {
		case .source(let element):
			try transform(element)
		case .target(let element):
			try transform(element)
		case .pair(source: let source, target: let target):
			if let result = try transform(target) {
				result
			}
			else {
				try transform(source)
			}
		}
	}
	
	/// Resolves the delta to a single element, favoring the element on the given side.
	///
	/// If the favored element is not available, the other element is returned.
	@inlinable
	public consuming func resolve(favoring side: Side) -> Element {
		switch side {
		case .source:
			switch consume self {
			case .source(let source): source
			case .target(let target): target
			case .pair(let source, _): source
			}
		case .target:
			switch consume self {
			case .source(let source): source
			case .target(let target): target
			case .pair(_, let target): target
			}
		}
	}
	
	/// Resolves the delta to a single element, merging the source and target elements in the pair case.
	///
	/// `merge` is called only in the pair case.
	@inlinable
	public consuming func coalesce<E>(
		_ merge: (_ source: consuming Element, _ target: consuming Element) throws(E) -> Element,
	) throws(E) -> Element {
		switch consume self {
		case .source(let source):
			source
		case .target(let target):
			target
		case .pair(let source, let target):
			try merge(source, target)
		}
	}
	
	/// Returns whether the delta is of the pair case and a predicate is true given the source and target elements.
	///
	/// A source delta or target delta always returns `false` without invoking `predicate`.
	///
	/// - Parameter predicate: The return value of this function is returned by `isIdentity(by:)`.
	///
	/// ### Examples
	///
	/// ```swift
	/// let delta = Delta.identity(5)
	/// assert(delta.isIdentity { $0 == $1 })
	/// ```
	///
	/// ```swift
	/// let delta = Delta.pair(source: -5, target: 5)
	/// assert(delta.isIdentity { abs($0) == abs($1) })
	/// ```
	///
	/// ```swift
	/// let delta = Delta.target(5)
	/// assert(!delta.isIdentity { $0 == $1 })
	/// ```
	@inlinable
	public func isIdentity<E>(
		by predicate: (_ source: borrowing Element, _ target: borrowing Element) throws(E) -> Bool,
	) throws(E) -> Bool {
		switch self {
		case .source(_):
			false
		case .target(_):
			false
		case .pair(let source, let target):
			try predicate(source, target)
		}
	}
	
	/// Returns the result of processing an intermediate delta.
	///
	/// Within `intermediateContext`, `transform` must be called with an intermediate element.
	/// An intermediate delta is created from this element (or elements, in case of a pair delta, where `intermediateContext` is called a second time nested in the first call).
	/// `process` is passed this intermediate delta and its return value is in turn returned by this method.
	///
	/// This mapping to an intermediate delta is helpful in cases where regular mapping would violate the lifetime of an element.
	///
	/// For example, mapping a `Delta<[UInt8]>` to a `Delta<UnsafeRawBufferPointer>` is normally a programming error as the pointer is only valid for the duration of the closure’s execution:
	///
	/// ```swift
	/// let arrayDelta = Delta<[UInt8]>.source([0x00, 0x01, 0x02])
	/// let pointerDelta = arrayDelta.map { array in
	///     return array.withUnsafeBytes { $0 }
	/// }
	/// // processing `pointerDelta` is a programming error:
	/// // not safe to use its elements outside `withUnsafeBytes`
	/// ```
	///
	/// Instead, use this method to safely map a delta to a delta with intermediate elements.
	///
	/// ```swift
	/// arrayDelta.withIntermediate { array, transform in
	///     return array.withUnsafeBytes { transform($0) }
	/// } process: { pointerDelta in
	///     // processing `pointerDelta` here is OK
	/// }
	/// ```
	///
	/// The argument to `process` is valid only for the duration of the closure’s execution.
	///
	/// - Throws: Errors thrown by either `intermediateContext` or `process` are rethrown.
	@inlinable
	public func withIntermediate<E, I, T>(
		// this is escaping to fulfill <https://github.com/swiftlang/swift-evolution/blob/main/proposals/0176-enforce-exclusive-access-to-memory.md#restrictions-on-recursive-uses-of-non-escaping-closures>
		_ intermediateContext: @escaping (
			_ element: borrowing Element,
			_ transform: (I) throws(E) -> T,
		) throws(E) -> T,
		process: (borrowing Delta<I>) throws(E) -> T,
	) throws(E) -> T {
		switch self {
		case .source(let element):
			return try intermediateContext(element) { intermediate throws(E) in
				try process(.source(intermediate))
			}
		case .target(let element):
			return try intermediateContext(element) { intermediate throws(E) in
				try process(.target(intermediate))
			}
		case .pair(source: let source, target: let target):
			return try intermediateContext(source) { sourceIntermediate throws(E) in
				try intermediateContext(target) { targetIntermediate throws(E) in
					try process(.pair(source: sourceIntermediate, target: targetIntermediate))
				}
			}
		}
	}
}

extension Delta: Copyable where Element: Copyable {
	/// Returns a pair delta where both the source and target share the same element.
	@inlinable
	public static func identity(_ element: Element) -> Self {
		.pair(source: element, target: element)
	}
	
	/// The source element, if available; otherwise, `nil`.
	@inlinable
	public var source: Element? {
		switch self {
		case .source(let source): source
		case .target(_): nil
		case .pair(let source, _): source
		}
	}
	
	/// The target element, if available; otherwise, `nil`.
	@inlinable
	public var target: Element? {
		switch self {
		case .source(_): nil
		case .target(let target): target
		case .pair(_, let target): target
		}
	}
	
	/// Returns a pair with the source and target elements, in the pair case; otherwise, `nil`.
	@inlinable
	public var pair: Pair? {
		switch self {
		case .source(_), .target(_):
			nil
		case .pair(source: let source, target: let target):
			Pair(source: source, target: target)
		}
	}
	
	/// Returns the element from the specified side, if available; otherwise, `nil`.
	@inlinable
	public subscript(_ side: Side) -> Element? {
		switch side {
		case .source:
			self.source
		case .target:
			self.target
		}
	}
	
	@inlinable
	public var first: Element {
		switch self {
		case .source(let source):
			source
		case .target(let target):
			target
		case .pair(source: let source, target: _):
			source
		}
	}
	
	@inlinable
	public var last: Element {
		switch self {
		case .source(let source):
			source
		case .target(let target):
			target
		case .pair(source: _, target: let target):
			target
		}
	}
	
	/// Returns a new delta composed of the elements of the two deltas, provided both are of the same case.
	///
	/// If both `self` and `other` are of the same case, their elements are paired and returned in a new delta.
	/// Otherwise, `nil` is returned.
	@inlinable
	public func compose<T>(
		with other: Delta<T>,
	) -> Delta<(Element, T)>? {
		switch self {
		case .source(let e1):
			guard case .source(let e2) = other else {
				return nil
			}
			return .source((e1, e2))
		case .target(let e1):
			guard case .target(let e2) = other else {
				return nil
			}
			return .target((e1, e2))
		case .pair(let s1, let t1):
			guard case .pair(source: let s2, target: let t2) = other else {
				return nil
			}
			return .pair(source: (s1, s2), target: (t1, t2))
		}
	}
	
	/// Returns a new delta composed of the elements of the deltas, provided all are of the same case.
	///
	/// If `self` and all `other` deltas are of the same case, their elements are packed in tuple and returned in a new delta.
	/// Otherwise, `nil` is returned.
	@_disfavoredOverload
	@inlinable
	public func compose<each T>(
		with other: repeat Delta<each T>,
	) -> Delta<(Element, repeat each T)>? {
		switch self {
		case .source(let e1):
			for delta in repeat each other {
				guard case .source(_) = delta else {
					return nil
				}
			}
			return .source((e1, repeat (each other).source.unsafelyUnwrapped))
		case .target(let e1):
			for delta in repeat each other {
				guard case .target(_) = delta else {
					return nil
				}
			}
			return .target((e1, repeat (each other).target.unsafelyUnwrapped))
		case .pair(let s1, let t1):
			for delta in repeat each other {
				guard case .pair(source: _, target: _) = delta else {
					return nil
				}
			}
			return .pair(
				source: (s1, repeat (each other).source.unsafelyUnwrapped),
				target: (t1, repeat (each other).target.unsafelyUnwrapped))
		}
	}
	
	#if !$Embedded
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements.
	///
	/// In the pair case, both elements are transformed concurrently.
	@available(macOS 10.15, iOS 13, tvOS 13, visionOS 1, watchOS 6, *)
	@inlinable
	public func asyncMap<E, T>(
		_ transform: @Sendable (Element) async throws(E) -> T,
	) async throws(E) -> Delta<T> where Element: Sendable {
		switch self {
		case .source(let source):
			return .source(try await transform(source))
		case .target(let target):
			return .target(try await transform(target))
		case .pair(let source, let target):
			do {
				async let transformedSource = transform(source)
				async let transformedTarget = transform(target)
				return try await .pair(source: transformedSource, target: transformedTarget)
			}
			catch let error as E {
				throw error
			}
			catch {
				preconditionFailure()
			}
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements, or `nil`, if the closure returns `nil` for all elements.
	///
	/// In the pair case, both elements are transformed concurrently.
	@available(macOS 10.15, iOS 13, tvOS 13, visionOS 1, watchOS 6, *)
	@inlinable
	public func asyncMapAny<E, T>(
		_ transform: @Sendable (Element) async throws(E) -> T?,
	) async throws(E) -> Delta<T>? where Element: Sendable {
		switch self {
		case .source(let source):
			guard let source = try await transform(source) else {
				return nil
			}
			return .source(source)
		case .target(let target):
			guard let target = try await transform(target) else {
				return nil
			}
			return .target(target)
		case .pair(let source, let target):
			do {
				async let source = transform(source)
				async let target = transform(target)
				
				if let source = try await source {
					if let target = try await target {
						return .pair(source: source, target: target)
					}
					else {
						return .source(source)
					}
				}
				else if let target = try await target {
					return .target(target)
				}
				else {
					return nil
				}
			}
			catch let error as E {
				throw error
			}
			catch {
				preconditionFailure()
			}
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements, or `nil`, if the closure returns `nil` for any element.
	///
	/// In the pair case, both elements are transformed concurrently.
	@available(macOS 10.15, iOS 13, tvOS 13, visionOS 1, watchOS 6, *)
	@inlinable
	public func asyncMapAll<E, T>(
		_ transform: @Sendable (Element) async throws(E) -> T?,
	) async throws(E) -> Delta<T>? where Element: Sendable {
		switch self {
		case .source(let source):
			guard let source = try await transform(source) else {
				return nil
			}
			return .source(source)
		case .target(let target):
			guard let target = try await transform(target) else {
				return nil
			}
			return .target(target)
		case .pair(let source, let target):
			do {
				async let source = transform(source)
				async let target = transform(target)
				guard let source = try await source,
				      let target = try await target else {
					return nil
				}
				return .pair(source: source, target: target)
			}
			catch let error as E {
				throw error
			}
			catch {
				preconditionFailure()
			}
		}
	}
	#endif
}

extension Delta: Sendable where Element: Sendable {}

extension Delta: BitwiseCopyable where Element: BitwiseCopyable {}

extension Delta: Equatable where Element: Equatable {
	/// Returns whether the delta is of the pair case with the source element equal to the target element.
	///
	/// Whether this is an identity delta is determined using the equality of `Equatable`, not reference identity (`===`).
	///
	/// A source delta or target delta always returns `false`.
	///
	/// ### Examples
	///
	/// ```swift
	/// let delta = Delta.identity(5)
	/// assert(delta.isIdentity())
	/// ```
	///
	/// ```swift
	/// let delta = Delta.pair(source: 5, target: 5)
	/// assert(delta.isIdentity())
	/// ```
	///
	/// ```swift
	/// let delta = Delta.target(5)
	/// assert(!delta.isIdentity())
	/// ```
	@inlinable
	public func isIdentity() -> Bool {
		switch self {
		case .source(_), .target(_):
			false
		case .pair(source: let source, target: let target):
			source == target
		}
	}
}

extension Delta: Hashable where Element: Hashable {}

extension Delta: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
		case .source(let source):
			"Delta(source: \(source))"
		case .target(let target):
			"Delta(target: \(target))"
		case .pair(let source, let target):
			"Delta(source: \(source), target: \(target))"
		}
	}
}

#if !$Embedded
extension Delta where Element: ~Copyable {
	public enum CodingKeys: String, CodingKey {
		case source = "a"
		case target = "b"
	}
}

extension Delta: Encodable where Element: Encodable {
	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .source(let source):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(source, forKey: .source)
		case .target(let target):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(target, forKey: .target)
		case .pair(let source, let target):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(source, forKey: .source)
			try container.encode(target, forKey: .target)
		}
	}
}

#if canImport(Foundation)
import Foundation

@available(macOS 12, iOS 15, tvOS 15, visionOS 1, watchOS 8, *)
extension Delta: EncodableWithConfiguration where Element: EncodableWithConfiguration {
	public typealias EncodingConfiguration = Element.EncodingConfiguration
	
	public func encode(to encoder: any Encoder, configuration: Element.EncodingConfiguration) throws {
		switch self {
		case .source(let source):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(source, forKey: .source, configuration: configuration)
		case .target(let target):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(target, forKey: .target, configuration: configuration)
		case .pair(let source, let target):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(source, forKey: .source, configuration: configuration)
			try container.encode(target, forKey: .target, configuration: configuration)
		}
	}
}
#endif

extension Delta: Decodable where Element: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let source = try container.decodeIfPresent(Element.self, forKey: .source)
		let target = try container.decodeIfPresent(Element.self, forKey: .target)
		
		if let source, let target {
			self = .pair(source: source, target: target)
		}
		else if let source {
			self = .source(source)
		}
		else if let target {
			self = .target(target)
		}
		else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No source or target value."))
		}
	}
}

#if canImport(Foundation)
import Foundation

@available(macOS 12, iOS 15, tvOS 15, visionOS 1, watchOS 8, *)
extension Delta: DecodableWithConfiguration where Element: DecodableWithConfiguration {
	public typealias DecodingConfiguration = Element.DecodingConfiguration
	
	public init(from decoder: any Decoder, configuration: Element.DecodingConfiguration) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let source = try container.decodeIfPresent(Element.self, forKey: .source, configuration: configuration)
		let target = try container.decodeIfPresent(Element.self, forKey: .target, configuration: configuration)
		
		if let source, let target {
			self = .pair(source: source, target: target)
		}
		else if let source {
			self = .source(source)
		}
		else if let target {
			self = .target(target)
		}
		else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No source or target value."))
		}
	}
}
#endif
#endif

extension Delta: RandomAccessCollection {
	public struct Index: Hashable, Sendable, BitwiseCopyable {
		@usableFromInline
		enum Step: Int8, Sendable, BitwiseCopyable {
			case source = 0
			case target = 1
			case sentinel = 2
		}
		
		@usableFromInline
		let step: Step
		
		@usableFromInline
		init(step: Step) {
			self.step = step
		}
	}
	
	public enum SubSequence {
		case empty(Index)
		case delta(Delta)
	}
	
	public typealias Iterator = _DeltaIterator<Element>
	
	@inlinable
	public func makeIterator() -> Iterator {
		Iterator(base: .delta(self), index: self.startIndex)
	}
	
	/// A delta is never empty as it always has either 1 or 2 elements.
	@inlinable
	public var isEmpty: Bool {
		false
	}
	
	/// The number of elements in the delta.
	///
	/// The value is always either 1 or 2.
	@inlinable
	public var count: Int {
		switch self {
		case .source(_), .target(_): 1
		case .pair(source: _, target: _): 2
		}
	}
	
	@inlinable
	public var underestimatedCount: Int {
		self.count
	}
	
	@inlinable
	public var startIndex: Index {
		switch self {
		case .source(_): Index(step: .source)
		case .target(_): Index(step: .target)
		case .pair(source: _, target: _): Index(step: .source)
		}
	}
	
	@inlinable
	public var endIndex: Index {
		switch self {
		case .source(_): Index(step: .target)
		case .target(_): Index(step: .sentinel)
		case .pair(source: _, target: _): Index(step: .sentinel)
		}
	}
	
	@inlinable
	public func index(after i: Index) -> Index {
		i.advanced(by: 1)
	}
	
	@inlinable
	public func index(before i: Index) -> Index {
		i.advanced(by: -1)
	}
	
	@inlinable
	public subscript(position: Index) -> Element {
		switch self {
		case .source(let source):
			guard position.step == .source else {
				preconditionFailure("index out of bounds")
			}
			return source
		case .target(let target):
			guard position.step == .target else {
				preconditionFailure("index out of bounds")
			}
			return target
		case .pair(let source, let target):
			switch position.step {
			case .source:
				return source
			case .target:
				return target
			case .sentinel:
				preconditionFailure("index out of bounds")
			}
		}
	}
	
	@inlinable
	public subscript(bounds: Range<Index>) -> SubSequence {
		guard bounds.lowerBound.step != bounds.upperBound.step else {
			return .empty(bounds.lowerBound)
		}
		switch (bounds.lowerBound.step, bounds.upperBound.step) {
		case (.source, .target):
			guard let source = self.source else {
				preconditionFailure("range out of bounds")
			}
			return .delta(.source(source))
		case (.target, .sentinel):
			guard let target = self.target else {
				preconditionFailure("range out of bounds")
			}
			return .delta(.target(target))
		case (.source, .sentinel):
			guard case .pair(source: let source, target: let target) = self else {
				preconditionFailure("range out of bounds")
			}
			return .delta(.pair(source: source, target: target))
		default:
			preconditionFailure("invalid range")
		}
	}
	
	@inlinable
	public subscript(unbounded: UnboundedRange) -> SubSequence {
		.delta(self)
	}
}

extension Delta.Index: Comparable {
	@inlinable
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.step.rawValue < rhs.step.rawValue
	}
}

extension Delta.Index: Strideable {
	public typealias Stride = Int
	
	@inlinable
	public func distance(to other: Delta<Element>.Index) -> Stride {
		Int(other.step.rawValue - self.step.rawValue)
	}
	
	@inlinable
	public func advanced(by n: Stride) -> Delta<Element>.Index {
		Self(step: Step(rawValue: self.step.rawValue + Int8(n))!)
	}
}

extension Delta.SubSequence: RandomAccessCollection {
	public typealias Index = Delta<Element>.Index
	
	public typealias SubSequence = Self
	
	public typealias Iterator = Delta<Element>.Iterator
	
	@inlinable
	public func makeIterator() -> Iterator {
		Iterator(base: self, index: self.startIndex)
	}
	
	@inlinable
	public var count: Int {
		switch self {
		case .empty(_): 0
		case .delta(let delta): delta.count
		}
	}
	
	@inlinable
	public var underestimatedCount: Int {
		self.count
	}
	
	@inlinable
	public var startIndex: Index {
		switch self {
		case .empty(let index):
			index
		case .delta(let delta):
			switch delta {
			case .source(_): Index(step: .source)
			case .target(_): Index(step: .target)
			case .pair(source: _, target: _): Index(step: .source)
			}
		}
	}
	
	@inlinable
	public var endIndex: Index {
		switch self {
		case .empty(let index):
			index
		case .delta(let delta):
			switch delta {
			case .source(_): Index(step: .target)
			case .target(_): Index(step: .sentinel)
			case .pair(source: _, target: _): Index(step: .sentinel)
			}
		}
	}
	
	@inlinable
	public func index(after i: Index) -> Index {
		i.advanced(by: 1)
	}
	
	@inlinable
	public func index(before i: Index) -> Index {
		i.advanced(by: -1)
	}
	
	@inlinable
	public subscript(position: Index) -> Element {
		guard case .delta(let delta) = self else {
			preconditionFailure("index out of bounds")
		}
		return delta[position]
	}
	
	@inlinable
	public subscript(bounds: Range<Index>) -> SubSequence {
		switch self {
		case .empty(let index):
			guard index == bounds.lowerBound && index == bounds.upperBound else {
				preconditionFailure("range out of bounds")
			}
			return self
		case .delta(let delta):
			return delta[bounds]
		}
	}
	
	@inlinable
	public subscript(unbounded: UnboundedRange) -> SubSequence {
		self
	}
}
