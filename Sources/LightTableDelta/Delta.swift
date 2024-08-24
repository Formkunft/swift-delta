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

public enum Delta<Element> {
	public typealias Element = Element
	public typealias Side = DeltaSide
	
	case deleted(source: Element)
	case added(target: Element)
	case modified(source: Element, target: Element)
	
	@inlinable @inline(__always)
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
	
	@inlinable @inline(__always)
	public init(source: Element?, target: Element) {
		if let source {
			self = .modified(source: source, target: target)
		}
		else {
			self = .added(target: target)
		}
	}
	
	@_disfavoredOverload
	@inlinable @inline(__always)
	public init(source: Element, target: Element?) {
		if let target {
			self = .modified(source: source, target: target)
		}
		else {
			self = .deleted(source: source)
		}
	}
	
	@inlinable @inline(__always)
	public var source: Element? {
		switch self {
		case .deleted(let source): source
		case .added(_): nil
		case .modified(let source, _): source
		}
	}
	
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
	public func map<T>(_ transform: (Element) throws -> T) rethrows -> Delta<T> {
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
	public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> Delta<T>? {
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
	/// In the `modified` case, `transform` is applied concurrently to both sides.
	@available(macOS 10.15.0, *)
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
	/// In the `modified` case, `transform` is applied concurrently to both sides.
	@available(macOS 10.15.0, *)
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
	
	@inlinable @inline(__always)
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
}

extension Delta: Equatable where Element: Equatable {}
extension Delta: Hashable where Element: Hashable {}
extension Delta: Encodable where Element: Encodable {}
extension Delta: Decodable where Element: Decodable {}
extension Delta: Sendable where Element: Sendable {}
