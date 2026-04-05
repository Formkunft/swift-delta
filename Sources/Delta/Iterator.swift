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
			case .pair(source: let source, target: _):
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
			case .pair(source: _, target: let target):
				self.index = Delta.Index(step: .sentinel)
				return target
			}
		case .sentinel:
			return nil
		}
	}
}
