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

public extension Delta where Element: ~Copyable {
	/// Returns a delta containing the results of mapping the given closure over the delta’s elements.
	@inlinable
	consuming func map<E, T: ~Copyable>(
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
	consuming func mapAny<E, T: ~Copyable>(
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
			return if source != nil && target != nil {
				.transition(source: source!, target: target!)
			}
			else if let source {
				.source(source)
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
	consuming func mapAll<E, T: ~Copyable>(
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
	consuming func resolve(favoring side: Side) -> Element {
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
	consuming func merge<E>(
		coalesce: (consuming Element, consuming Element) throws(E) -> Element
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
}

extension Delta: Copyable where Element: Copyable {
	/// Returns a transition delta where both the source and target share the same element.
	@inlinable @inline(__always)
	public static func transition(_ element: Element) -> Self {
		.transition(source: element, target: element)
	}
	
	/// The source element, if available; otherwise, `nil`.
	@inlinable @inline(__always)
	public var source: Element? {
		switch self {
		case .source(let source): source
		case .target(_): nil
		case .transition(let source, _): source
		}
	}
	
	/// The target element, if available; otherwise, `nil`.
	@inlinable @inline(__always)
	public var target: Element? {
		switch self {
		case .source(_): nil
		case .target(let target): target
		case .transition(_, let target): target
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

extension Delta: Equatable where Element: Equatable {}

extension Delta: Hashable where Element: Hashable {}

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

extension Delta: Sendable where Element: Sendable {}

extension Delta: BitwiseCopyable where Element: BitwiseCopyable {}
