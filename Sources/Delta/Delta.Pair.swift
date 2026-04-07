//
//  Copyright 2026 Florian Pircher
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

extension Delta where Element: ~Copyable {
	/// A type representing both a source and a target element.
	@frozen
	public struct Pair: ~Copyable {
		/// The type of the elements.
		public typealias Element = Delta.Element
		
		/// A source element.
		public var source: Element
		/// A target element.
		public var target: Element
		
		/// Creates a pair.
		@inlinable
		public init(source: consuming Element, target: consuming Element) {
			self.source = source
			self.target = target
		}
	}
}

extension Delta.Pair where Element: ~Copyable {
	/// Creates a pair when both elements are non-`nil`; otherwise, returns `nil`.
	@inlinable
	public init?(source: consuming Element?, target: consuming Element?) {
		guard let source, let target else {
			return nil
		}
		self.init(source: source, target: target)
	}
	
	/// Returns a pair with the source and target elements, in the pair case; otherwise, `nil`.
	@inlinable
	public init?(_ delta: consuming Delta) {
		switch consume delta {
		case .source(_):
			return nil
		case .target(_):
			return nil
		case .pair(source: let source, target: let target):
			self = Delta.Pair(source: source, target: target)
		}
	}
	
	/// Swaps the source and target sides of the pair in place.
	@inlinable
	public mutating func reverse() {
		self = (consume self).reversed()
	}
	
	/// Returns a pair with the source and target sides swapped.
	@inlinable
	public consuming func reversed() -> Delta.Pair {
		.init(source: self.target, target: self.source)
	}
	
	/// Returns a pair containing the results of mapping the given closure over the pair’s elements.
	@inlinable
	public consuming func map<E, T: ~Copyable>(
		_ transform: (consuming Element) throws(E) -> T,
	) throws(E) -> Delta<T>.Pair {
		.init(
			source: try transform(self.source),
			target: try transform(self.target))
	}
	
	/// Returns a delta containing the results of mapping the given closure over the pair’s elements, or `nil`, if the closure returns `nil` for both elements.
	@inlinable
	public consuming func mapAny<E, T: ~Copyable>(
		_ transform: (consuming Element) throws(E) -> T?,
	) throws(E) -> Delta<T>? {
		let source = try transform(self.source)
		let target = try transform(self.target)
		
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
	
	/// Returns a pair containing the results of mapping the given closure over the pair’s elements, or `nil`, if the closure returns `nil` for any element.
	///
	/// Instead of passing the identity function, `{ $0 }`, consider using the equivalent ``compacted()`` instead.
	@inlinable
	public consuming func mapAll<E, T: ~Copyable>(
		_ transform: (consuming Element) throws(E) -> T?,
	) throws(E) -> Delta<T>.Pair? {
		guard let source = try transform(self.source),
		      let target = try transform(self.target) else {
			return nil
		}
		return .init(source: source, target: target)
	}
	
	/// Returns a pair with non-optional elements or `nil`, if any of the elements is `nil`.
	///
	/// This is equivalent to ``mapAll(_:)`` with the identity function `{ $0 }` as its argument.
	@inlinable
	public consuming func compacted<T>() -> Delta<T>.Pair? where T? == Element {
		guard let source, let target else {
			return nil
		}
		return .init(source: source, target: target)
	}
	
	/// Applies a transformation to the elements in source–target order and returns the first non-`nil` result.
	///
	/// Returns `nil` when the transformation returns `nil` for both elements.
	@inlinable
	public func firstNonNilMap<E, T: ~Copyable>(
		_ transform: (borrowing Element) throws(E) -> T?,
	) throws(E) -> T? {
		if let result = try transform(self.source) {
			result
		}
		else {
			try transform(self.target)
		}
	}
	
	/// Applies a transformation to the elements in target–source order and returns the first non-`nil` result.
	///
	/// Returns `nil` when the transformation returns `nil` for both elements.
	@inlinable
	public func lastNonNilMap<E, T: ~Copyable>(
		_ transform: (borrowing Element) throws(E) -> T?,
	) throws(E) -> T? {
		if let result = try transform(self.target) {
			result
		}
		else {
			try transform(self.source)
		}
	}
	
	/// Modifies the pair by providing mutable access to both sides using a function.
	///
	/// The function is first called for the source and then for the target element.
	@inlinable
	public mutating func update(
		_ code: (_ element: inout Element) -> (),
	) {
		code(&self.source)
		code(&self.target)
	}
	
	/// Modifies the pair by providing mutable access to both sides using a function.
	///
	/// The function is first called for the source and then for the target element.
	@inlinable
	public mutating func update(
		_ code: (_ element: inout Element, _ side: Delta.Side) -> (),
	) {
		code(&self.source, .source)
		code(&self.target, .target)
	}
	
	/// Returns whether a predicate is true given the source and target elements.
	///
	/// - Parameter predicate: The return value of this function is returned by `isIdentity(by:)`.
	@inlinable
	public func isIdentity<E>(
		by predicate: (_ source: borrowing Element, _ target: borrowing Element) throws(E) -> Bool,
	) throws(E) -> Bool {
		try predicate(self.source, self.target)
	}
	
	/// Returns the result of processing an intermediate pair.
	///
	/// Within `intermediateContext`, `transform` must be called with an intermediate element.
	/// `intermediateContext` is called twice, once for the source element and once, nested in the first call, for the target element.
	/// An intermediate pair is created from these elements.
	/// `process` is passed this intermediate pair and its return value is in turn returned by this method.
	///
	/// This mapping to an intermediate pair is helpful in cases where regular mapping would violate the lifetime of an element.
	///
	/// For example, mapping a `Delta<[UInt8]>.Pair` to a `Delta<UnsafeRawBufferPointer>.Pair` is normally a programming error as the pointer is only valid for the duration of the closure’s execution:
	///
	/// ```swift
	/// let arrayPair = Delta<[UInt8]>.Pair(source: [0x00], target: [0x00, 0x01])
	/// let pointerPair = arrayPair.map { array in
	///     return array.withUnsafeBytes { $0 }
	/// }
	/// // processing `pointerPair` is a programming error:
	/// // not safe to use its elements outside `withUnsafeBytes`
	/// ```
	///
	/// Instead, use this method to safely map a pair to a pair with intermediate elements.
	///
	/// ```swift
	/// arrayPair.withIntermediate { array, transform in
	///     return array.withUnsafeBytes { transform($0) }
	/// } process: { pointerPair in
	///     // processing `pointerPair` here is OK
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
		process: (borrowing Delta<I>.Pair) throws(E) -> T,
	) throws(E) -> T {
		try intermediateContext(self.source) { sourceIntermediate throws(E) in
			try intermediateContext(self.target) { targetIntermediate throws(E) in
				try process(.init(source: sourceIntermediate, target: targetIntermediate))
			}
		}
	}
}

extension Delta.Pair: Copyable where Element: Copyable {
	/// Returns a pair where both the source and target share the same element.
	@inlinable
	public static func identity(_ element: Element) -> Self {
		.init(source: element, target: element)
	}
	
	/// Returns the source and target element as a tuple.
	@inlinable
	public var elements: (source: Element, target: Element) {
		(source: self.source, target: self.target)
	}
	
	/// Accesses the element from the specified side.
	@inlinable
	public subscript(_ side: Delta.Side) -> Element {
		set {
			switch side {
			case .source:
				self.source = newValue
			case .target:
				self.target = newValue
			}
		}
		get {
			switch side {
			case .source:
				self.source
			case .target:
				self.target
			}
		}
	}
	
	/// Returns a new pair composed of the elements of the two pairs.
	@inlinable
	public func compose<T>(
		with other: Delta<T>.Pair,
	) -> Delta<(Element, T)>.Pair {
		.init(
			source: (self.source, other.source),
			target: (self.target, other.target))
	}
	
	/// Returns a new pair composed of the elements of the pairs.
	@_disfavoredOverload
	@inlinable
	public func compose<each T>(
		with other: repeat Delta<each T>.Pair,
	) -> Delta<(Element, repeat each T)>.Pair {
		.init(
			source: (self.source, repeat (each other).source),
			target: (self.target, repeat (each other).target))
	}
	
	#if !$Embedded
	/// Returns a pair containing the results of mapping the given closure over the pair’s elements.
	///
	/// Both elements are transformed concurrently.
	@available(macOS 10.15, iOS 13, tvOS 13, visionOS 1, watchOS 6, *)
	@inlinable
	public func asyncMap<E, T>(
		_ transform: @Sendable (Element) async throws(E) -> T,
	) async throws(E) -> Delta<T>.Pair where Element: Sendable {
		do {
			async let transformedSource = transform(self.source)
			async let transformedTarget = transform(self.target)
			return try await .init(source: transformedSource, target: transformedTarget)
		}
		catch let error as E {
			throw error
		}
		catch {
			preconditionFailure()
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the pair’s elements, or `nil`, if the closure returns `nil` for both elements.
	///
	/// Both elements are transformed concurrently.
	@available(macOS 10.15, iOS 13, tvOS 13, visionOS 1, watchOS 6, *)
	@inlinable
	public func asyncMapAny<E, T>(
		_ transform: @Sendable (Element) async throws(E) -> T?,
	) async throws(E) -> Delta<T>? where Element: Sendable {
		do {
			async let source = transform(self.source)
			async let target = transform(self.target)
			
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
	
	/// Returns a pair containing the results of mapping the given closure over the pair’s elements, or `nil`, if the closure returns `nil` for any element.
	///
	/// Both elements are transformed concurrently.
	@available(macOS 10.15, iOS 13, tvOS 13, visionOS 1, watchOS 6, *)
	@inlinable
	public func asyncMapAll<E, T>(
		_ transform: @Sendable (Element) async throws(E) -> T?,
	) async throws(E) -> Delta<T>.Pair? where Element: Sendable {
		do {
			async let source = transform(self.source)
			async let target = transform(self.target)
			guard let source = try await source,
			      let target = try await target else {
				return nil
			}
			return .init(source: source, target: target)
		}
		catch let error as E {
			throw error
		}
		catch {
			preconditionFailure()
		}
	}
	#endif
}

extension Delta.Pair: Sendable where Element: Sendable {}

extension Delta.Pair: BitwiseCopyable where Element: BitwiseCopyable {}

extension Delta.Pair: Equatable where Element: Equatable {
	/// Returns whether the source element is equal to the target element.
	///
	/// Whether this is an identity pair is determined using the equality of `Equatable`, not reference identity (`===`).
	@inlinable
	public func isIdentity() -> Bool {
		self.source == self.target
	}
}

extension Delta.Pair: Hashable where Element: Hashable {}

extension Delta.Pair: CustomDebugStringConvertible {
	public var debugDescription: String {
		"Delta.Pair(source: \(source), target: \(target))"
	}
}

#if !$Embedded
extension Delta.Pair where Element: ~Copyable {
	public enum CodingKeys: String, CodingKey {
		case source = "a"
		case target = "b"
	}
}

extension Delta.Pair: Encodable where Element: Encodable {}

#if canImport(Foundation)
import Foundation

@available(macOS 12, iOS 15, tvOS 15, visionOS 1, watchOS 8, *)
extension Delta.Pair: EncodableWithConfiguration where Element: EncodableWithConfiguration {
	public typealias EncodingConfiguration = Element.EncodingConfiguration
	
	public func encode(to encoder: any Encoder, configuration: Element.EncodingConfiguration) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.source, forKey: .source, configuration: configuration)
		try container.encode(self.target, forKey: .target, configuration: configuration)
	}
}
#endif

extension Delta.Pair: Decodable where Element: Decodable {}

#if canImport(Foundation)
import Foundation

@available(macOS 12, iOS 15, tvOS 15, visionOS 1, watchOS 8, *)
extension Delta.Pair: DecodableWithConfiguration where Element: DecodableWithConfiguration {
	public typealias DecodingConfiguration = Element.DecodingConfiguration
	
	public init(from decoder: any Decoder, configuration: Element.DecodingConfiguration) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let source = try container.decodeIfPresent(Element.self, forKey: .source, configuration: configuration)
		let target = try container.decodeIfPresent(Element.self, forKey: .target, configuration: configuration)
		
		guard let source, let target else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No source or target value."))
		}
		
		self.init(source: source, target: target)
	}
}
#endif
#endif

extension Delta.Pair: RandomAccessCollection {
	public typealias Index = Delta.Index
	
	public typealias SubSequence = Delta.SubSequence
	
	public typealias Iterator = _DeltaIterator<Element>
	
	@inlinable
	public func makeIterator() -> Iterator {
		Iterator(base: .delta(Delta(self)), index: self.startIndex)
	}
	
	/// A pair is never empty as it always has 2 elements.
	@inlinable
	public var isEmpty: Bool {
		false
	}
	
	/// The number of elements in the pair.
	///
	/// The value is always 2.
	@inlinable
	public var count: Int {
		2
	}
	
	@inlinable
	public var underestimatedCount: Int {
		self.count
	}
	
	@inlinable
	public var startIndex: Index {
		Index(step: .source)
	}
	
	@inlinable
	public var endIndex: Index {
		Index(step: .sentinel)
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
		switch position.step {
		case .source:
			return self.source
		case .target:
			return self.target
		case .sentinel:
			preconditionFailure("index out of bounds")
		}
	}
	
	@inlinable
	public subscript(bounds: Range<Index>) -> SubSequence {
		guard bounds.lowerBound.step != bounds.upperBound.step else {
			return .empty(bounds.lowerBound)
		}
		switch (bounds.lowerBound.step, bounds.upperBound.step) {
		case (.source, .target):
			return .delta(.source(self.source))
		case (.target, .sentinel):
			return .delta(.target(self.target))
		case (.source, .sentinel):
			return .delta(.pair(source: self.source, target: self.target))
		default:
			preconditionFailure("invalid range")
		}
	}
	
	@inlinable
	public subscript(unbounded: UnboundedRange) -> SubSequence {
		.delta(Delta(self))
	}
}
