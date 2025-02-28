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
import Foundation
import LightTableDelta

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
	
	let jsonDataModified =  Data(#"{"A":3,"B":5}"#.utf8)
	let deltaModified = try decoder.decode(Delta<Int>.self, from: jsonDataModified)
	#expect(deltaModified == .transition(source: 3, target: 5))
	
	let jsonDataEmpty =  Data("{}".utf8)
	#expect(throws: DecodingError.self, performing: { try decoder.decode(Delta<Int>.self, from: jsonDataEmpty) })
}

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
