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

	static let defaultChunkSize: Bytes = (6 * 1024 * 1024)
	
	let chunkIndex: Int

	let fileURL: URL
	let uploadURL: URL
	let uploadIdentifier: String

	let size: Bytes
	let byteOffset: Bytes
}

extension Chunk {
	init(file: File, response: AddUploadURLResponse) {
		let chunkIndex = response.partNumber - 1
		let byteOffset = Chunk.defaultChunkSize * Bytes(chunkIndex)
		self.init(chunkIndex: chunkIndex,
				  fileURL: file.url,
				  uploadURL: response.uploadUrl,
				  uploadIdentifier: response.uploadId,
				  size: min(file.filesize - byteOffset, Chunk.defaultChunkSize),
				  byteOffset: byteOffset)
	}
}

extension Data {
	init(from chunk: Chunk) throws {
		let file = try FileHandle(forReadingFrom: chunk.fileURL)
		file.seek(toFileOffset: UInt64(chunk.byteOffset))
		self = file.readData(ofLength: Int(chunk.size))
	}
}
