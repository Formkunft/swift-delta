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
	let elements1 = Array(Delta.source(3))
	#expect(elements1 == [3])
	
	let elements2 = Array(Delta.target(5))
	#expect(elements2 == [5])
	
	let elements3 = Array(Delta.transition(source: 3, target: 5))
	#expect(elements3 == [3, 5])
}

@Test func collection() {
	let delta1 = Delta.source(3)
	#expect(delta1.first == 3)
	#expect(delta1[delta1.startIndex] == 3)
	
	let delta2 = Delta.target(5)
	#expect(delta2.first == 5)
	#expect(delta2[delta2.startIndex] == 5)
	
	let delta3 = Delta.transition(source: 3, target: 5)
	#expect(delta3.first == 3)
	#expect(delta3[delta3.startIndex] == 3)
	#expect(delta3[delta3.index(after: delta3.startIndex)] == 5)
}
