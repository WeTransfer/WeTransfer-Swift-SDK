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

	/// Size of all chunks except the last, as the last chunk holds the remaining data (filesize % defaultChunkSize)
	static let defaultChunkSize: Bytes = (6 * 1024 * 1024)
	
	/// Zero-based index of chunk
	/// - Note: Server-side these are called partNumber and start at 1
	let chunkIndex: Int

	/// File URL pointing to local file from File struct
	let fileURL: URL
	/// URL to upload the chunk to
	let uploadURL: URL
	
	/// Size of the chunk in bytes
	let size: Bytes
	/// Offset of the chunk in bytes. This is from where to read the data from the file
	let byteOffset: Bytes
}

extension Chunk {
	/// Initializes a chunk from its File, an index and the URL it should be uploaded to. This struct will be used to upload the file in seperate chunks. For each chunk the size and offset are calculated with the bytes available in the File
	///
	/// - Parameters:
	///   - file: The file for which the chunk should be created
	///   - chunkIndex: The index of the chunk
	///   - uploadURL: The URL to where the chunk should be uploaded
	init(file: File, chunkIndex: Int, uploadURL: URL) {
		let byteOffset = Chunk.defaultChunkSize * Bytes(chunkIndex)
		self.init(chunkIndex: chunkIndex,
				  fileURL: file.url,
				  uploadURL: uploadURL,
				  size: min(file.filesize - byteOffset, Chunk.defaultChunkSize),
				  byteOffset: byteOffset)
	}
}

extension Data {
	/// Initializes a Data object pointing to the correct bytes in the file of the chunk
	///
	/// - Parameter chunk: The chunk with the information about the file, the size and the byte offset
	/// - Throws: Any error thrown from initializing the FileHandle
	init(from chunk: Chunk) throws {
		let file = try FileHandle(forReadingFrom: chunk.fileURL)
		file.seek(toFileOffset: UInt64(chunk.byteOffset))
		self = file.readData(ofLength: Int(chunk.size))
	}
}
