import Testing
import Foundation
import LightTableDelta

@Test func encoding() async throws {
	let encoder = JSONEncoder()
	encoder.outputFormatting = .sortedKeys
	
	let jsonDataDeleted = try encoder.encode(Delta.deleted(source: 3))
	let jsonDeleted = String(decoding: jsonDataDeleted, as: UTF8.self)
	#expect(jsonDeleted == #"{"A":3}"#)
	
	let jsonDataAdded = try encoder.encode(Delta.added(target: 5))
	let jsonAdded = String(decoding: jsonDataAdded, as: UTF8.self)
	#expect(jsonAdded == #"{"B":5}"#)
	
	let jsonDataModified = try encoder.encode(Delta.modified(source: 3, target: 5))
	let jsonModified = String(decoding: jsonDataModified, as: UTF8.self)
	#expect(jsonModified == #"{"A":3,"B":5}"#)
}

@Test func decoding() async throws {
	let decoder = JSONDecoder()
	
	let jsonDataDeleted = Data(#"{"A":3}"#.utf8)
	let deltaDeleted = try decoder.decode(Delta<Int>.self, from: jsonDataDeleted)
	#expect(deltaDeleted == .deleted(source: 3))
	
	let jsonDataAdded = Data( #"{"B":5}"#.utf8)
	let deltaAdded = try decoder.decode(Delta<Int>.self, from: jsonDataAdded)
	#expect(deltaAdded == .added(target: 5))
	
	let jsonDataModified =  Data(#"{"A":3,"B":5}"#.utf8)
	let deltaModified = try decoder.decode(Delta<Int>.self, from: jsonDataModified)
	#expect(deltaModified == .modified(source: 3, target: 5))
	
	let jsonDataEmpty =  Data("{}".utf8)
	#expect(throws: DecodingError.self, performing: { try decoder.decode(Delta<Int>.self, from: jsonDataEmpty) })
}
