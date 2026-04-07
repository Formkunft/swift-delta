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

import Testing
import Delta

#if canImport(Foundation)
import Foundation
#endif

@Suite
struct `Delta Pair tests` {
	@Test func `init`() {
		let p = Delta.Pair(source: 3, target: 5)
		#expect(p.source == 3)
		#expect(p.target == 5)
	}
	
	@Test func `init both optional`() {
		let p1 = Delta.Pair(source: 3 as Int?, target: 5 as Int?)
		#expect(p1 != nil)
		#expect(p1!.source == 3)
		#expect(p1!.target == 5)
		
		let p2 = Delta.Pair(source: nil as Int?, target: 5 as Int?)
		#expect(p2 == nil)
		
		let p3 = Delta.Pair(source: 3 as Int?, target: nil as Int?)
		#expect(p3 == nil)
		
		let p4 = Delta.Pair(source: nil as Int?, target: nil as Int?)
		#expect(p4 == nil)
	}
	
	@Test func reversed() {
		let p = Delta.Pair(source: 3, target: 5).reversed()
		#expect(p.source == 5)
		#expect(p.target == 3)
	}
	
	@Test func reverse() {
		var p = Delta.Pair(source: 3, target: 5)
		p.reverse()
		#expect(p.source == 5)
		#expect(p.target == 3)
	}
	
	@Test func map() {
		let p = Delta.Pair(source: 3, target: 5).map { $0 * 2 }
		#expect(p.source == 6)
		#expect(p.target == 10)
	}
	
	@Test func `map any`() {
		// both non-nil
		let d1 = Delta.Pair(source: 3, target: 5).mapAny {
			if $0 > 0 { $0 - 1 } else { nil }
		}
		#expect(d1 == .pair(source: 2, target: 4))
		
		// source nil
		let d2 = Delta.Pair(source: 3, target: 5).mapAny {
			if $0 > 4 { $0 - 1 } else { nil }
		}
		#expect(d2 == .target(4))
		
		// target nil
		let d3 = Delta.Pair(source: 3, target: 5).mapAny {
			if $0 < 4 { $0 - 1 } else { nil }
		}
		#expect(d3 == .source(2))
		
		// both nil
		let d4 = Delta.Pair(source: 3, target: 5).mapAny {
			if $0 > 10 { $0 - 1 } else { nil }
		}
		#expect(d4 == nil)
	}
	
	@Test func `map all`() {
		// both non-nil
		let p1 = Delta.Pair(source: 3, target: 5).mapAll {
			if $0 > 0 { $0 - 1 } else { nil }
		}
		#expect(p1 != nil)
		#expect(p1!.source == 2)
		#expect(p1!.target == 4)
		
		// source nil
		let p2 = Delta.Pair(source: 3, target: 5).mapAll {
			if $0 > 4 { $0 - 1 } else { nil }
		}
		#expect(p2 == nil)
		
		// target nil
		let p3 = Delta.Pair(source: 3, target: 5).mapAll {
			if $0 < 4 { $0 - 1 } else { nil }
		}
		#expect(p3 == nil)
		
		// both nil
		let p4 = Delta.Pair(source: 3, target: 5).mapAll {
			if $0 > 10 { $0 - 1 } else { nil }
		}
		#expect(p4 == nil)
	}
	
	@Test func compacted() {
		// both non-nil
		let p1 = Delta<Int?>.Pair(source: 3, target: 5).compacted()
		#expect(p1 != nil)
		#expect(p1!.source == 3)
		#expect(p1!.target == 5)
		
		// source nil
		let p2 = Delta<Int?>.Pair(source: nil, target: 5).compacted()
		#expect(p2 == nil)
		
		// target nil
		let p3 = Delta<Int?>.Pair(source: 3, target: nil).compacted()
		#expect(p3 == nil)
		
		// both nil
		let p4 = Delta<Int?>.Pair(source: nil, target: nil).compacted()
		#expect(p4 == nil)
	}
	
	@Test func `first non-nil map`() {
		// both non-nil: returns source (first)
		#expect(Delta.Pair(source: "3", target: "5").firstNonNilMap(Int.init) == 3)
		// source nil, target non-nil: returns target
		#expect(Delta.Pair(source: "x", target: "5").firstNonNilMap(Int.init) == 5)
		// source non-nil, target nil: returns source
		#expect(Delta.Pair(source: "3", target: "y").firstNonNilMap(Int.init) == 3)
		// both nil
		#expect(Delta.Pair(source: "x", target: "y").firstNonNilMap(Int.init) == nil)
	}
	
	@Test func `last non-nil map`() {
		// both non-nil: returns target (last)
		#expect(Delta.Pair(source: "3", target: "5").lastNonNilMap(Int.init) == 5)
		// source nil, target non-nil: returns target
		#expect(Delta.Pair(source: "x", target: "5").lastNonNilMap(Int.init) == 5)
		// source non-nil, target nil: returns source
		#expect(Delta.Pair(source: "3", target: "y").lastNonNilMap(Int.init) == 3)
		// both nil
		#expect(Delta.Pair(source: "x", target: "y").lastNonNilMap(Int.init) == nil)
	}
	
	@Test func `is identity`() {
		let p1 = Delta.Pair.identity(5)
		#expect(p1.isIdentity { $0 == $1 })
		#expect(p1.isIdentity())
		
		let p2 = Delta.Pair(source: -5, target: 5)
		#expect(p2.isIdentity { abs($0) == abs($1) })
		#expect(!p2.isIdentity())
		
		let p3 = Delta.Pair(source: 3, target: 5)
		#expect(!p3.isIdentity())
	}
	
	@Test func identity() {
		let p = Delta.Pair.identity(5)
		#expect(p.source == 5)
		#expect(p.target == 5)
	}
	
	@Test func delta() {
		let p = Delta.Pair(source: 3, target: 5)
		#expect(Delta(p) == .pair(source: 3, target: 5))
	}
	
	@Test func elements() {
		let p = Delta.Pair(source: 3, target: 5)
		let (source, target) = p.elements
		#expect(source == 3)
		#expect(target == 5)
	}
	
	@Test func `subscript side get`() {
		let p = Delta.Pair(source: 3, target: 5)
		#expect(p[.source] == 3)
		#expect(p[.target] == 5)
	}
	
	@Test func `subscript side set`() {
		var p = Delta.Pair(source: 3, target: 5)
		
		p[.source] = 7
		#expect(p[.source] == 7)
		#expect(p[.target] == 5)
		
		p[.target] = 9
		#expect(p[.source] == 7)
		#expect(p[.target] == 9)
	}
	
	@Test func compose() {
		let p = Delta.Pair(source: 3, target: 5)
			.compose(with: .init(source: 7, target: 9))
		#expect(p.source == (3, 7))
		#expect(p.target == (5, 9))
	}
	
	@Test func `compose multiple`() {
		let p = Delta.Pair(source: 3, target: 5)
			.compose(with: .init(source: 7, target: 9), .init(source: 11, target: 13))
		#expect(p.source == (3, 7, 11))
		#expect(p.target == (5, 9, 13))
	}
	
	@Test func `async map`() async {
		let p = await Delta.Pair(source: 3, target: 5).asyncMap { $0 * 2 }
		#expect(p.source == 6)
		#expect(p.target == 10)
	}
	
	@Test func `async map any`() async {
		// both non-nil
		let d1 = await Delta.Pair(source: 3, target: 5).asyncMapAny {
			if $0 > 0 { $0 - 1 } else { nil }
		}
		#expect(d1 == .pair(source: 2, target: 4))
		
		// source nil
		let d2 = await Delta.Pair(source: 3, target: 5).asyncMapAny {
			if $0 > 4 { $0 - 1 } else { nil }
		}
		#expect(d2 == .target(4))
		
		// target nil
		let d3 = await Delta.Pair(source: 3, target: 5).asyncMapAny {
			if $0 < 4 { $0 - 1 } else { nil }
		}
		#expect(d3 == .source(2))
		
		// both nil
		let d4 = await Delta.Pair(source: 3, target: 5).asyncMapAny {
			if $0 > 10 { $0 - 1 } else { nil }
		}
		#expect(d4 == nil)
	}
	
	@Test func `async map all`() async {
		// both non-nil
		let p1 = await Delta.Pair(source: 3, target: 5).asyncMapAll {
			if $0 > 0 { $0 - 1 } else { nil }
		}
		#expect(p1 != nil)
		#expect(p1!.source == 2)
		#expect(p1!.target == 4)
		
		// source nil
		let p2 = await Delta.Pair(source: 3, target: 5).asyncMapAll {
			if $0 > 4 { $0 - 1 } else { nil }
		}
		#expect(p2 == nil)
		
		// target nil
		let p3 = await Delta.Pair(source: 3, target: 5).asyncMapAll {
			if $0 < 4 { $0 - 1 } else { nil }
		}
		#expect(p3 == nil)
		
		// both nil
		let p4 = await Delta.Pair(source: 3, target: 5).asyncMapAll {
			if $0 > 10 { $0 - 1 } else { nil }
		}
		#expect(p4 == nil)
	}
	
	#if canImport(Foundation)
	@Test func encoding() throws {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .sortedKeys
		
		let jsonData = try encoder.encode(Delta.Pair(source: 3, target: 5))
		let json = String(decoding: jsonData, as: UTF8.self)
		#expect(json == #"{"a":3,"b":5}"#)
	}
	
	@Test func decoding() throws {
		let decoder = JSONDecoder()
		
		let jsonData = Data(#"{"a":3,"b":5}"#.utf8)
		let pair = try decoder.decode(Delta<Int>.Pair.self, from: jsonData)
		#expect(pair.source == 3)
		#expect(pair.target == 5)
		
		let jsonDataMissing = Data(#"{"a":3}"#.utf8)
		#expect(throws: DecodingError.self, performing: { try decoder.decode(Delta<Int>.Pair.self, from: jsonDataMissing) })
		
		let jsonDataEmpty = Data("{}".utf8)
		#expect(throws: DecodingError.self, performing: { try decoder.decode(Delta<Int>.Pair.self, from: jsonDataEmpty) })
	}
	#endif
	
	@Test func sequence() {
		let p = Delta.Pair(source: 3, target: 5)
		#expect(Array(p) == [3, 5])
	}
	
	@Test func collection() {
		let p = Delta.Pair(source: 3, target: 5)
		#expect(p.first == 3)
		#expect(p[p.startIndex] == 3)
		#expect(p[p.index(after: p.startIndex)] == 5)
	}
	
	@Test func `distance to`() {
		let p = Delta.Pair(source: 3, target: 5)
		#expect(p.startIndex.distance(to: p.endIndex) == 2)
		#expect(p.endIndex.distance(to: p.startIndex) == -2)
		#expect(p.startIndex.distance(to: p.index(after: p.startIndex)) == 1)
	}
	
	@Test func `bidirectional collection`() {
		let p = Delta.Pair(source: 3, target: 5)
		#expect(p.last == 5)
		#expect(p[p.index(before: p.endIndex)] == 5)
		#expect(p[p.index(before: p.index(before: p.endIndex))] == 3)
	}
	
	@Test func subsequence() {
		let p = Delta.Pair(source: 3, target: 5)
		let tests = [
			(p.startIndex ..< p.startIndex, []),
			(p.endIndex ..< p.endIndex, []),
			(p.startIndex ..< p.index(after: p.startIndex), [3]),
			(p.index(after: p.startIndex) ..< p.endIndex, [5]),
			(p.startIndex ..< p.endIndex, [3, 5]),
		]
		for (range, elements) in tests {
			#expect(p[range].elementsEqual(elements))
			#expect(p[range][range].elementsEqual(elements))
			#expect(p[range][range][range].elementsEqual(elements))
		}
		#expect(p[...].elementsEqual([3, 5]))
		#expect(p[...][...].elementsEqual([3, 5]))
		#expect(p[...][...][...].elementsEqual([3, 5]))
	}
}
