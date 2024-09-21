//
//  Delta.swift
//  LightTableDelta
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
public enum Delta<Element> {
	/// The type of the elements.
	public typealias Element = Element
	public typealias Side = DeltaSide
	
	enum CodingKeys: String, CodingKey {
		case source = "A"
		case target = "B"
	}
	
	/// A source element.
	///
	/// Conceptually, this is a value that was deleted and thus no target element is available.
	case deleted(source: Element)
	/// A target element.
	///
	/// Conceptually, this is a value that was added and thus no source element is available.
	case added(target: Element)
	/// A source element and a target element.
	///
	/// Conceptually, this is a value that was modified and both the source and the target element are available.
	/// The source and target elements can be different or equal.
	case modified(source: Element, target: Element)
	
	/// Returns a modified delta where both the source and target share the same element.
	@inlinable @inline(__always)
	public static func equal(_ element: Element) -> Self {
		.modified(source: element, target: element)
	}
	
	/// Creates a modified delta from a source and a target element.
	@inlinable @inline(__always)
	public init(source: Element, target: Element) {
		self = .modified(source: source, target: target)
	}
	
	/// Creates a delta from a source and a target element.
	///
	/// If the source element is `nil`, the delta is `.added(target:)`.
	/// Otherwise, the delta is `.modified(source:target:)`.
	@inlinable
	public init(source: Element?, target: Element) {
		if let source {
			self = .modified(source: source, target: target)
		}
		else {
			self = .added(target: target)
		}
	}
	
	/// Creates a delta from a source and a target element.
	///
	/// If the target element is `nil`, the delta is `.deleted(source:)`.
	/// Otherwise, the delta is `.modified(source:target:)`.
	@inlinable
	public init(source: Element, target: Element?) {
		if let target {
			self = .modified(source: source, target: target)
		}
		else {
			self = .deleted(source: source)
		}
	}
	
	/// Creates a delta from a source and a target element.
	///
	/// If both the source and the target element are `nil`, the delta is `nil`.
	/// If the source element is `nil`, the delta is `.added(target:)`.
	/// If the target element is `nil`, the delta is `.deleted(source:)`.
	/// Otherwise, the delta is `.modified(source:target:)`.
	@inlinable
	public init?(source: Element?, target: Element?) {
		if let source, let target {
			self = .modified(source: source, target: target)
		}
		else if let source {
			self = .deleted(source: source)
		}
		else if let target {
			self = .added(target: target)
		}
		else {
			return nil
		}
	}
	
	/// The source element, if the delta value is not of type `.added`.
	@inlinable @inline(__always)
	public var source: Element? {
		switch self {
		case .deleted(let source): source
		case .added(_): nil
		case .modified(let source, _): source
		}
	}
	
	/// The target element, if the delta value is not of type `.deleted`.
	@inlinable @inline(__always)
	public var target: Element? {
		switch self {
		case .deleted(_): nil
		case .added(let target): target
		case .modified(_, let target): target
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements.
	@inlinable
	public func map<T, E>(
		_ transform: (Element) throws(E) -> T
	) throws(E) -> Delta<T> {
		switch self {
		case .deleted(let source):
			.deleted(source: try transform(source))
		case .added(let target):
			.added(target: try transform(target))
		case .modified(let source, let target):
			.modified(source: try transform(source), target: try transform(target))
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements, or `nil`, if the closure returns `nil` for any element.
	@inlinable
	public func flatMap<T, E>(
		_ transform: (Element) throws(E) -> T?
	) throws(E) -> Delta<T>? {
		switch self {
		case .deleted(let source):
			guard let source = try transform(source) else {
				return nil
			}
			return .deleted(source: source)
		case .added(let target):
			guard let target = try transform(target) else {
				return nil
			}
			return .added(target: target)
		case .modified(let source, let target):
			guard let source = try transform(source),
				  let target = try transform(target) else {
				return nil
			}
			return .modified(source: source, target: target)
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements.
	///
	/// In the `.modified` case, `transform` is applied concurrently to both sides.
	@available(macOS 10.15, iOS 13, tvOS 13, visionOS 1, watchOS 6, *)
	@inlinable
	public func asyncMap<T>(
		_ transform: @Sendable (Element) async -> T
	) async -> Delta<T> where Element: Sendable {
		switch self {
		case .deleted(let source):
			return .deleted(source: await transform(source))
		case .added(let target):
			return .added(target: await transform(target))
		case .modified(let source, let target):
			async let transformedSource = transform(source)
			async let transformedTarget = transform(target)
			return await .modified(source: transformedSource, target: transformedTarget)
		}
	}
	
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements.
	///
	/// In the `.modified` case, `transform` is applied concurrently to both sides.
	@available(macOS 10.15, iOS 13, tvOS 13, visionOS 1, watchOS 6, *)
	@inlinable
	public func asyncMap<T>(
		_ transform: @Sendable (Element) async throws -> T
	) async throws -> Delta<T> where Element: Sendable {
		switch self {
		case .deleted(let source):
			return .deleted(source: try await transform(source))
		case .added(let target):
			return .added(target: try await transform(target))
		case .modified(let source, let target):
			async let transformedSource = transform(source)
			async let transformedTarget = transform(target)
			return try await .modified(source: transformedSource, target: transformedTarget)
		}
	}
	
	/// Returns a reduced view of the delta, favoring the given side.
	///
	/// If an element is available on the favored side, it is returned.
	/// Otherwise, the element on the other side is returned.
	@inlinable
	public func unified(favoring side: Side) -> Element {
		switch side {
		case .source:
			switch self {
			case .deleted(let source): source
			case .added(let target): target
			case .modified(let source, _): source
			}
		case .target:
			switch self {
			case .deleted(let source): source
			case .added(let target): target
			case .modified(_, let target): target
			}
		}
	}
	
	/// Returns the combined value of the source and target element, if modified, otherwise returns the source or target value.
	@inlinable
	public func reduce<E>(
		combine: (Element, Element) throws(E) -> Element
	) throws(E) -> Element {
		switch self {
		case .deleted(let source):
			source
		case .added(let target):
			target
		case .modified(let source, let target):
			try combine(source, target)
		}
	}
}

extension Delta: Equatable where Element: Equatable {}

extension Delta: Hashable where Element: Hashable {}

extension Delta: Encodable where Element: Encodable {
	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .deleted(let source):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(source, forKey: .source)
		case .added(let target):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(target, forKey: .target)
		case .modified(let source, let target):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(source, forKey: .source)
			try container.encode(target, forKey: .target)
		}
	}
}

extension Delta: Decodable where Element: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let source = try container.decodeIfPresent(Element.self, forKey: .source)
		let target = try container.decodeIfPresent(Element.self, forKey: .target)
		
		if let source, let target {
			self = .modified(source: source, target: target)
		}
		else if let source {
			self = .deleted(source: source)
		}
		else if let target {
			self = .added(target: target)
		}
		else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No source or target value."))
		}
	}
}

extension Delta: Sendable where Element: Sendable {}

extension Delta: BitwiseCopyable where Element: BitwiseCopyable {}
