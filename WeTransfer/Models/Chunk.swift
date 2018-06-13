//
//  Chunk.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Represents a chunk of data from a file in a transfer. Used only in the uploading proces
struct Chunk: Encodable {

	public let chunkIndex: Int
	static let defaultChunkSize: Bytes = (6 * 1024 * 1024)

	let fileURL: URL
	let uploadURL: URL
	let uploadIdentifier: String

	public let chunkSize: Bytes
	public let byteOffset: Bytes
}

extension Chunk {
	init(file: File, response: AddUploadURLResponse) {
		chunkIndex = response.partNumber - 1
		fileURL = file.url
		uploadURL = response.uploadUrl
		uploadIdentifier = response.uploadId
		byteOffset = Chunk.defaultChunkSize * Bytes(chunkIndex)
		chunkSize = min(file.filesize - byteOffset, Chunk.defaultChunkSize)
	}
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
