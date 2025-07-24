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

import Testing
import DeltaModule

@Test func resolve() {
	let element1 = Delta.source(3).resolve(favoring: .source)
	#expect(element1 == 3)

	let element2 = Delta.source(3).resolve(favoring: .target)
	#expect(element2 == 3)
	
	let element3 = Delta.target(5).resolve(favoring: .source)
	#expect(element3 == 5)
	
	let element4 = Delta.target(5).resolve(favoring: .target)
	#expect(element4 == 5)
	
	let element5 = Delta.transition(source: 3, target: 5).resolve(favoring: .source)
	#expect(element5 == 3)
	
	let element6 = Delta.transition(source: 3, target: 5).resolve(favoring: .target)
	#expect(element6 == 5)
}

@Test func coalesce() {
	let element1 = Delta.source(3).coalesce { $0 + $1 }
	#expect(element1 == 3)
	
	let element2 = Delta.target(5).coalesce { $0 + $1 }
	#expect(element2 == 5)
	
	let element3 = Delta.transition(source: 3, target: 5).coalesce { $0 + $1 }
	#expect(element3 == 8)
}

@Test func compose() {
	let delta1 = Delta.source(3).compose(with: .source(5))
	#expect(delta1 != nil)
	#expect(delta1!.source! == (3, 5))
	
	let delta2 = Delta.source(3).compose(with: .source("some string"))
	#expect(delta2 != nil)
	#expect(delta2!.source! == (3, "some string"))
	
	let delta3 = Delta.source(3).compose(with: .target(3))
	#expect(delta3 == nil)
	
	let delta4 = Delta.source(3).compose(with: .transition(source: 3, target: 3))
	#expect(delta4 == nil)
	
	let delta5 = Delta.target(3).compose(with: .source(3))
	#expect(delta5 == nil)
	
	let delta6 = Delta.transition(source: 3, target: 3).compose(with: .source(3))
	#expect(delta6 == nil)
}

@Test func composeMultiple() {
	let delta1 = Delta.source(3).compose(with: .source(5), .source(7))
	#expect(delta1 != nil)
	#expect(delta1!.source! == (3, 5, 7))
	
	let delta2 = Delta.source(3).compose(with: .source("some string"), .source([3.14, 1.41]))
	#expect(delta2 != nil)
	#expect(delta2!.source! == (3, "some string", [3.14, 1.41]))
	
	let delta3 = Delta.source(3).compose(with: .source(3), .target(3))
	#expect(delta3 == nil)
	
	let delta4 = Delta.source(3).compose(with: .target(3), .source(3))
	#expect(delta4 == nil)
	
	let delta5 = Delta.source(3).compose(with: .source(3), .transition(source: 3, target: 3))
	#expect(delta5 == nil)
	
	let delta6 = Delta.source(3).compose(with: .transition(source: 3, target: 3), .source(3))
	#expect(delta6 == nil)
	
	let delta7 = Delta.target(3).compose(with: .target(3), .source(3))
	#expect(delta7 == nil)
	
	let delta8 = Delta.target(3).compose(with: .source(3), .target(3))
	#expect(delta8 == nil)
	
	let delta9 = Delta.transition(source: 3, target: 3).compose(with: .transition(source: 3, target: 3), .source(3))
	#expect(delta9 == nil)
	
	let delta10 = Delta.transition(source: 3, target: 3).compose(with: .source(3), .transition(source: 3, target: 3))
	#expect(delta10 == nil)
}

@Test func map() {
	let delta1 = Delta.source(3).map { $0 * 2 }
	#expect(delta1 == .source(6))
	
	let delta2 = Delta.target(5).map { $0 + 1 }
	#expect(delta2 == .target(6))
	
	let delta3 = Delta.transition(source: 3, target: 5).map { $0 - 1 }
	#expect(delta3 == .transition(source: 2, target: 4))
}

@Test func asyncMap() async {
	let delta1 = await Delta.source(3).asyncMap { $0 * 2 }
	#expect(delta1 == .source(6))
	
	let delta2 = await Delta.target(5).asyncMap { $0 + 1 }
	#expect(delta2 == .target(6))
	
	let delta3 = await Delta.transition(source: 3, target: 5).asyncMap { $0 - 1 }
	#expect(delta3 == .transition(source: 2, target: 4))
}

@Test func mapAny() {
	let delta1 = Delta.source(3).mapAny {
		if $0 > 0 { $0 * 2 } else { nil }
	}
	#expect(delta1 == .source(6))
	
	let delta2 = Delta.source(3).mapAny {
		if $0 > 10 { $0 + 2 } else { nil }
	}
	#expect(delta2 == nil)
	
	let delta3 = Delta.target(5).mapAny {
		if $0 > 0 { $0 + 1 } else { nil }
	}
	#expect(delta3 == .target(6))
	
	let delta4 = Delta.target(5).mapAny {
		if $0 > 10 { $0 + 1 } else { nil }
	}
	#expect(delta4 == nil)
	
	let delta5 = Delta.transition(source: 3, target: 5).mapAny {
		if $0 > 0 { $0 - 1 } else { nil }
	}
	#expect(delta5 == .transition(source: 2, target: 4))
	
	let delta6 = Delta.transition(source: 3, target: 5).mapAny {
		if $0 > 4 { $0 - 1 } else { nil }
	}
	#expect(delta6 == .target(4))
	
	let delta7 = Delta.transition(source: 3, target: 5).mapAny {
		if $0 < 4 { $0 - 1 } else { nil }
	}
	#expect(delta7 == .source(2))
	
	let delta8 = Delta.transition(source: 3, target: 5).mapAny {
		if $0 > 10 { $0 - 1 } else { nil }
	}
	#expect(delta8 == nil)
}

@Test func asyncMapAny() async {
	let delta1 = await Delta.source(3).asyncMapAny {
		if $0 > 0 { $0 * 2 } else { nil }
	}
	#expect(delta1 == .source(6))
	
	let delta2 = await Delta.source(3).asyncMapAny {
		if $0 > 10 { $0 + 2 } else { nil }
	}
	#expect(delta2 == nil)
	
	let delta3 = await Delta.target(5).asyncMapAny {
		if $0 > 0 { $0 + 1 } else { nil }
	}
	#expect(delta3 == .target(6))
	
	let delta4 = await Delta.target(5).asyncMapAny {
		if $0 > 10 { $0 + 1 } else { nil }
	}
	#expect(delta4 == nil)
	
	let delta5 = await Delta.transition(source: 3, target: 5).asyncMapAny {
		if $0 > 0 { $0 - 1 } else { nil }
	}
	#expect(delta5 == .transition(source: 2, target: 4))
	
	let delta6 = await Delta.transition(source: 3, target: 5).asyncMapAny {
		if $0 > 4 { $0 - 1 } else { nil }
	}
	#expect(delta6 == .target(4))
	
	let delta7 = await Delta.transition(source: 3, target: 5).asyncMapAny {
		if $0 < 4 { $0 - 1 } else { nil }
	}
	#expect(delta7 == .source(2))
	
	let delta8 = await Delta.transition(source: 3, target: 5).asyncMapAny {
		if $0 > 10 { $0 - 1 } else { nil }
	}
	#expect(delta8 == nil)
}

@Test func mapAll() {
	let delta1 = Delta.source(3).mapAll {
		if $0 > 0 { $0 * 2 } else { nil }
	}
	#expect(delta1 == .source(6))
	
	let delta2 = Delta.source(3).mapAll {
		if $0 > 10 { $0 + 2 } else { nil }
	}
	#expect(delta2 == nil)
	
	let delta3 = Delta.target(5).mapAll {
		if $0 > 0 { $0 + 1 } else { nil }
	}
	#expect(delta3 == .target(6))
	
	let delta4 = Delta.target(5).mapAll {
		if $0 > 10 { $0 + 1 } else { nil }
	}
	#expect(delta4 == nil)
	
	let delta5 = Delta.transition(source: 3, target: 5).mapAll {
		if $0 > 0 { $0 - 1 } else { nil }
	}
	#expect(delta5 == .transition(source: 2, target: 4))
	
	let delta6 = Delta.transition(source: 3, target: 5).mapAll {
		if $0 > 4 { $0 - 1 } else { nil }
	}
	#expect(delta6 == nil)
	
	let delta7 = Delta.transition(source: 3, target: 5).mapAll {
		if $0 < 4 { $0 - 1 } else { nil }
	}
	#expect(delta7 == nil)
	
	let delta8 = Delta.transition(source: 3, target: 5).mapAll {
		if $0 > 10 { $0 - 1 } else { nil }
	}
	#expect(delta8 == nil)
}

@Test func asyncMapAll() async {
	let delta1 = await Delta.source(3).asyncMapAll {
		if $0 > 0 { $0 * 2 } else { nil }
	}
	#expect(delta1 == .source(6))
	
	let delta2 = await Delta.source(3).asyncMapAll {
		if $0 > 10 { $0 + 2 } else { nil }
	}
	#expect(delta2 == nil)
	
	let delta3 = await Delta.target(5).asyncMapAll {
		if $0 > 0 { $0 + 1 } else { nil }
	}
	#expect(delta3 == .target(6))
	
	let delta4 = await Delta.target(5).asyncMapAll {
		if $0 > 10 { $0 + 1 } else { nil }
	}
	#expect(delta4 == nil)
	
	let delta5 = await Delta.transition(source: 3, target: 5).asyncMapAll {
		if $0 > 0 { $0 - 1 } else { nil }
	}
	#expect(delta5 == .transition(source: 2, target: 4))
	
	let delta6 = await Delta.transition(source: 3, target: 5).asyncMapAll {
		if $0 > 4 { $0 - 1 } else { nil }
	}
	#expect(delta6 == nil)
	
	let delta7 = await Delta.transition(source: 3, target: 5).asyncMapAll {
		if $0 < 4 { $0 - 1 } else { nil }
	}
	#expect(delta7 == nil)
	
	let delta8 = await Delta.transition(source: 3, target: 5).asyncMapAll {
		if $0 > 10 { $0 - 1 } else { nil }
	}
	#expect(delta8 == nil)
}

@Test func isIdentity() {
	let delta1 = Delta.identity(5)
	#expect(delta1.isIdentity { $0 == $1 })
	
	let delta2 = Delta.transition(source: -5, target: 5)
	#expect(delta2.isIdentity { abs($0) == abs($1) })
	
	let delta3 = Delta.target(5)
	#expect(!delta3.isIdentity { $0 == $1 })
	
	let delta4 = Delta.identity(5)
	#expect(delta4.isIdentity())
	
	let delta5 = Delta.transition(source: 5, target: 5)
	#expect(delta5.isIdentity())
	
	let delta6 = Delta.target(5)
	#expect(!delta6.isIdentity())
}

#if canImport(Foundation)
import Foundation

@Test func encoding() async throws {
	let encoder = JSONEncoder()
	encoder.outputFormatting = .sortedKeys
	
	let jsonDataDeleted = try encoder.encode(Delta.source(3))
	let jsonDeleted = String(decoding: jsonDataDeleted, as: UTF8.self)
	#expect(jsonDeleted == #"{"A":3}"#)
	
	let jsonDataAdded = try encoder.encode(Delta.target(5))
	let jsonAdded = String(decoding: jsonDataAdded, as: UTF8.self)
	#expect(jsonAdded == #"{"B":5}"#)
	
	let jsonDataModified = try encoder.encode(Delta.transition(source: 3, target: 5))
	let jsonModified = String(decoding: jsonDataModified, as: UTF8.self)
	#expect(jsonModified == #"{"A":3,"B":5}"#)
}

@Test func decoding() async throws {
	let decoder = JSONDecoder()
	
	let jsonDataDeleted = Data(#"{"A":3}"#.utf8)
	let deltaDeleted = try decoder.decode(Delta<Int>.self, from: jsonDataDeleted)
	#expect(deltaDeleted == .source(3))
	
	let jsonDataAdded = Data(#"{"B":5}"#.utf8)
	let deltaAdded = try decoder.decode(Delta<Int>.self, from: jsonDataAdded)
	#expect(deltaAdded == .target(5))
	
	let jsonDataModified = Data(#"{"A":3,"B":5}"#.utf8)
	let deltaModified = try decoder.decode(Delta<Int>.self, from: jsonDataModified)
	#expect(deltaModified == .transition(source: 3, target: 5))
	
	let jsonDataEmpty = Data("{}".utf8)
	#expect(throws: DecodingError.self, performing: { try decoder.decode(Delta<Int>.self, from: jsonDataEmpty) })
}
#endif

@Test func sequence() {
	let d1 = Delta.source(3)
	#expect(Array(d1) == [3])
	
	let d2 = Delta.target(5)
	#expect(Array(d2) == [5])
	
	let d3 = Delta.transition(source: 3, target: 5)
	#expect(Array(d3) == [3, 5])
	#expect(d3.starts(with: d1))
}

@Test func collection() {
	let d1 = Delta.source(3)
	#expect(d1.first == 3)
	#expect(d1[d1.startIndex] == 3)
	
	let d2 = Delta.target(5)
	#expect(d2.first == 5)
	#expect(d2[d2.startIndex] == 5)
	
	let d3 = Delta.transition(source: 3, target: 5)
	#expect(d3.first == 3)
	#expect(d3[d3.startIndex] == 3)
	#expect(d3[d3.index(after: d3.startIndex)] == 5)
}

@Test func bidirectionalCollection() {
	let d1 = Delta.source(3)
	#expect(d1.last == 3)
	#expect(d1[d1.index(before: d1.endIndex)] == 3)
	
	let d2 = Delta.target(5)
	#expect(d2.last == 5)
	#expect(d2[d2.index(before: d2.endIndex)] == 5)
	
	let d3 = Delta.transition(source: 3, target: 5)
	#expect(d3.last == 5)
	#expect(d3[d3.index(before: d3.endIndex)] == 5)
	#expect(d3[d3.index(before: d3.index(before: d3.endIndex))] == 3)
}

@Test func subsequence() {
	let d1 = Delta.source(3)
	let t1 = [
		(d1.startIndex ..< d1.startIndex, []),
		(d1.endIndex ..< d1.endIndex, []),
		(d1.startIndex ..< d1.endIndex, [3]),
	]
	for (range, elements) in t1 {
		#expect(d1[range].elementsEqual(elements))
		#expect(d1[range][range].elementsEqual(elements))
		#expect(d1[range][range][range].elementsEqual(elements))
	}
	#expect(d1[...].elementsEqual([3]))
	#expect(d1[...][...].elementsEqual([3]))
	#expect(d1[...][...][...].elementsEqual([3]))
	
	let d2 = Delta.target(5)
	let t2 = [
		(d2.startIndex ..< d2.startIndex, []),
		(d2.endIndex ..< d2.endIndex, []),
		(d2.startIndex ..< d2.endIndex, [5]),
	]
	for (range, elements) in t2 {
		#expect(d2[range].elementsEqual(elements))
		#expect(d2[range][range].elementsEqual(elements))
		#expect(d2[range][range][range].elementsEqual(elements))
	}
	#expect(d2[...].elementsEqual([5]))
	#expect(d2[...][...].elementsEqual([5]))
	#expect(d2[...][...][...].elementsEqual([5]))
	
	let d3 = Delta.transition(source: 3, target: 5)
	let t3 = [
		(d3.startIndex ..< d3.startIndex, []),
		(d3.endIndex ..< d3.endIndex, []),
		(d3.startIndex ..< d3.index(after: d3.startIndex), [3]),
		(d3.index(after: d3.startIndex) ..< d3.endIndex, [5]),
		(d3.startIndex ..< d3.endIndex, [3, 5]),
	]
	for (range, elements) in t3 {
		#expect(d3[range].elementsEqual(elements))
		#expect(d3[range][range].elementsEqual(elements))
		#expect(d3[range][range][range].elementsEqual(elements))
	}
	#expect(d3[...].elementsEqual([3, 5]))
	#expect(d3[...][...].elementsEqual([3, 5]))
	#expect(d3[...][...][...].elementsEqual([3, 5]))
}
