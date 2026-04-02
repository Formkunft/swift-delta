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

/// A description of the two sides of a delta value.
@frozen
public enum DeltaSide: String, Hashable, Comparable, Sendable, BitwiseCopyable, LosslessStringConvertible {
	case source
	case target
	
	@inlinable
	public init?(_ description: String) {
		self.init(rawValue: description)
	}
	
	/// The opposite side.
	@inlinable
	public var opposite: Self {
		switch self {
		case .source: .target
		case .target: .source
		}
	}
	
	@inlinable
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs == .source && rhs == .target
	}
	
	@inlinable
	public var description: String {
		self.rawValue
	}
}

extension Delta where Element: ~Copyable {
	/// A description of the two sides of a delta value.
	public typealias Side = DeltaSide
}
