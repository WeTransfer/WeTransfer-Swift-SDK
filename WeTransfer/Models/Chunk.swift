//
//  Chunk.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public struct Chunk: Encodable {

	public let chunkNumber: Int
	static let defaultChunkSize: Bytes = (6 * 1024 * 1024)

	let fileURL: URL
	let uploadURL: URL
	let uploadIdentifier: String

	public let chunkSize: Bytes
	public let byteOffset: Bytes
}

extension Chunk {

	func data() throws -> Data? {
		guard let file = try? FileHandle(forReadingFrom: fileURL) else {
			return nil
		}
		file.seek(toFileOffset: UInt64(byteOffset))
		return file.readData(ofLength: Int(chunkSize))
	}
}
