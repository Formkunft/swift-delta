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
public enum Delta<Element>: ~Copyable where Element: ~Copyable {
	/// The type of the elements.
	public typealias Element = Element
	public typealias Side = DeltaSide
	
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
	case transition(source: Element, target: Element)
}

public extension Delta where Element: ~Copyable {
	/// Creates a transition delta.
	@inlinable @inline(__always)
	init(source: consuming Element, target: consuming Element) {
		self = .transition(source: source, target: target)
	}
	
	/// Creates a target delta if `source` is `nil`; otherwise, creates a transition delta.
	@inlinable
	init(source: consuming Element?, target: consuming Element) {
		if let source {
			self = .transition(source: source, target: target)
		}
		else {
			self = .target(target)
		}
	}
	
	/// Creates a source delta if `target` is `nil`; otherwise, creates a transition delta.
	@inlinable
	init(source: consuming Element, target: consuming Element?) {
		if let target {
			self = .transition(source: source, target: target)
		}
		else {
			self = .source(source)
		}
	}
	
	/// Creates a delta when one or both elements are non-`nil`; otherwise, returns `nil`.
	///
	/// - If both the source and target are non-`nil`, creates a transition delta.
	/// - Else, if the source is non-`nil`, creates a source delta.
	/// - Else, if the target is non-`nil`, creates a target delta.
	/// - Otherwise, returns `nil`.
	@inlinable
	init?(source: consuming Element?, target: consuming Element?) {
		if source != nil && target != nil {
			self = .transition(source: source!, target: target!)
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
	/// Returns the side for source and target deltas and `nil` for transition deltas.
	@inlinable
	public var side: Side? {
		switch self {
		case .source(_): .source
		case .target(_): .target
		case .transition(source: _, target: _): nil
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements.
	@inlinable
	public consuming func map<E, T: ~Copyable>(
		_ transform: (consuming Element) throws(E) -> T
	) throws(E) -> Delta<T> {
		switch consume self {
		case .source(let source):
			.source(try transform(source))
		case .target(let target):
			.target(try transform(target))
		case .transition(let source, let target):
			.transition(source: try transform(source), target: try transform(target))
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements, or `nil`, if the closure returns `nil` for all elements.
	@inlinable
	public consuming func mapAny<E, T: ~Copyable>(
		_ transform: (consuming Element) throws(E) -> T?
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
		case .transition(let source, let target):
			let source = try transform(source)
			let target = try transform(target)
			return if let source {
				if let target {
					.transition(source: source, target: target)
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
		_ transform: (consuming Element) throws(E) -> T?
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
		case .transition(let source, let target):
			guard let source = try transform(source),
			      let target = try transform(target) else {
				return nil
			}
			return .transition(source: source, target: target)
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
			case .transition(let source, _): source
			}
		case .target:
			switch consume self {
			case .source(let source): source
			case .target(let target): target
			case .transition(_, let target): target
			}
		}
	}
	
	/// Resolves the delta to a single element, coalescing the source and target elements in the transition case.
	@inlinable
	public consuming func merge<E>(
		coalesce: (_ source: consuming Element, _ target: consuming Element) throws(E) -> Element
	) throws(E) -> Element {
		switch consume self {
		case .source(let source):
			source
		case .target(let target):
			target
		case .transition(let source, let target):
			try coalesce(source, target)
		}
	}
	
	/// Returns whether the delta is of the transition case and a predicate is true given the source and target elements.
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
	/// let delta = Delta.transition(source: -5, target: 5)
	/// assert(delta.isIdentity { abs($0) == abs($1) })
	/// ```
	///
	/// ```swift
	/// let delta = Delta.target(5)
	/// assert(!delta.isIdentity { $0 == $1 })
	/// ```
	@inlinable
	public func isIdentity<E>(
		by predicate: (_ source: borrowing Element, _ target: borrowing Element) throws(E) -> Bool
	) throws(E) -> Bool {
		switch self {
		case .source(_):
			false
		case .target(_):
			false
		case .transition(let source, let target):
			try predicate(source, target)
		}
	}
}

extension Delta: Copyable where Element: Copyable {
	/// Returns a transition delta where both the source and target share the same element.
	@inlinable
	public static func identity(_ element: Element) -> Self {
		.transition(source: element, target: element)
	}
	
	/// The source element, if available; otherwise, `nil`.
	@inlinable
	public var source: Element? {
		switch self {
		case .source(let source): source
		case .target(_): nil
		case .transition(let source, _): source
		}
	}
	
	/// The target element, if available; otherwise, `nil`.
	@inlinable
	public var target: Element? {
		switch self {
		case .source(_): nil
		case .target(let target): target
		case .transition(_, let target): target
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
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements.
	///
	/// In the transition case, both elements are transformed concurrently.
	@available(macOS 10.15, iOS 13, tvOS 13, visionOS 1, watchOS 6, *)
	@inlinable
	public func asyncMap<E, T>(
		_ transform: @Sendable (Element) async throws(E) -> T
	) async throws(E) -> Delta<T> where Element: Sendable {
		switch self {
		case .source(let source):
			return .source(try await transform(source))
		case .target(let target):
			return .target(try await transform(target))
		case .transition(let source, let target):
			do {
				async let transformedSource = transform(source)
				async let transformedTarget = transform(target)
				return try await .transition(source: transformedSource, target: transformedTarget)
			}
			catch let error as E {
				throw error
			}
			catch {
				preconditionFailure()
			}
		}
	}
}

extension Delta: Equatable where Element: Equatable {
	/// Returns whether the delta is of the transition case with the source element equal to the target element.
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
	/// let delta = Delta.transition(source: 5, target: 5)
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
		case .source(_):
			false
		case .target(_):
			false
		case .transition(source: let source, target: let target):
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
		case .transition(let source, let target):
			"Delta(source: \(source), target: \(target))"
		}
	}
}

public extension Delta where Element: ~Copyable {
	enum CodingKeys: String, CodingKey {
		case source = "A"
		case target = "B"
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
		case .transition(let source, let target):
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
		case .transition(let source, let target):
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
			self = .transition(source: source, target: target)
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
			self = .transition(source: source, target: target)
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

extension Delta: Sendable where Element: Sendable {}

extension Delta: BitwiseCopyable where Element: BitwiseCopyable {}

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
		case empty(Delta<Element>.Index)
		case delta(Delta<Element>)
	}
	
	public typealias Iterator = _DeltaIterator<Element>
	
	@inlinable
	public func makeIterator() -> Iterator {
		Iterator(base: .delta(self), index: self.startIndex)
	}
	
	/// The number of elements in the delta.
	@inlinable
	public var count: Int {
		switch self {
		case .source(_): 1
		case .target(_): 1
		case .transition(source: _, target: _): 2
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
		case .transition(source: _, target: _): Index(step: .source)
		}
	}
	
	@inlinable
	public var endIndex: Index {
		switch self {
		case .source(_): Index(step: .target)
		case .target(_): Index(step: .sentinel)
		case .transition(source: _, target: _): Index(step: .sentinel)
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
	
	/// The source element, if available; otherwise, the target element.
	@inlinable
	public var first: Element {
		self.resolve(favoring: .source)
	}
	
	/// The target element, if available; otherwise, the source element.
	@inlinable
	public var last: Element {
		self.resolve(favoring: .target)
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
		case .transition(let source, let target):
			switch position.step {
			case .source: return source
			case .target: return target
			case .sentinel: preconditionFailure("index out of bounds")
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
			guard case .transition(source: let source, target: let target) = self else {
				preconditionFailure("range out of bounds")
			}
			return .delta(.transition(source: source, target: target))
		default:
			preconditionFailure("invalid range")
		}
	}
	
	@inlinable
	public subscript(unbounded: UnboundedRange) -> SubSequence {
		self[self.startIndex ..< self.endIndex]
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
		Int(self.step.rawValue - other.step.rawValue)
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
			case .source(_): Delta.Index(step: .source)
			case .target(_): Delta.Index(step: .target)
			case .transition(source: _, target: _): Delta.Index(step: .source)
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
			case .source(_): Delta.Index(step: .target)
			case .target(_): Delta.Index(step: .sentinel)
			case .transition(source: _, target: _): Delta.Index(step: .sentinel)
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
		self[self.startIndex ..< self.endIndex]
	}
}

public struct _DeltaIterator<Element>: IteratorProtocol {
	@usableFromInline
	let base: Delta<Element>.SubSequence
	@usableFromInline
	var index: Delta<Element>.Index
	
	@inlinable
	init(base: Delta<Element>.SubSequence, index: Delta<Element>.Index) {
		self.base = base
		self.index = index
	}
	
	@inlinable
	public mutating func next() -> Element? {
		switch self.index.step {
		case .source:
			guard case .delta(let delta) = self.base else {
				return nil
			}
			switch delta {
			case .source(let source):
				self.index = Delta.Index(step: .sentinel)
				return source
			case .target(_):
				preconditionFailure("source index used with target delta")
			case .transition(source: let source, target: _):
				self.index = Delta.Index(step: .target)
				return source
			}
		case .target:
			guard case .delta(let delta) = self.base else {
				return nil
			}
			switch delta {
			case .source(_):
				preconditionFailure("target index used with source delta")
			case .target(let target):
				self.index = Delta.Index(step: .sentinel)
				return target
			case .transition(source: _, target: let target):
				self.index = Delta.Index(step: .sentinel)
				return target
			}
		case .sentinel:
			return nil
		}
	}
}
