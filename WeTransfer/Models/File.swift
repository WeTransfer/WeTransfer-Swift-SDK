//
//  File.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public typealias Bytes = UInt64

public struct File: Identifiable, Encodable {
	public let url: URL
	public private(set) var identifier: String?
	public internal(set) var uploaded: Bool = false

	public let filename: String
	public let filesize: Bytes
	let contentIdentifier: String = "file"
	let localIdentifier = UUID().uuidString

	public private(set) var numberOfChunks: Int?
	public private(set) var chunks: [Chunk] = []
	private(set) var multipartUploadIdentifier: String?

	public init?(url: URL) {
		self.url = url
		filename = url.lastPathComponent
		if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: url.path),
			let filesizeAttribute = fileAttributes[.size] as? UInt64 {
			self.filesize = filesizeAttribute
		} else {
			return nil
		}
	}
}

extension File: Equatable {
	public static func == (lhs: File, rhs: File) -> Bool {
		return lhs.url == rhs.url && lhs.localIdentifier == rhs.localIdentifier
	}
}

extension File {

	func updated(with response: WeTransfer.AddFilesResponse) -> File {
		var file = self
		file.identifier = response.id
		file.numberOfChunks = response.meta.multipartParts
		file.multipartUploadIdentifier = response.meta.multipartUploadId
		return file
	}

	func updated(with chunkResponse: WeTransfer.AddUploadURLResponse) -> File {
		guard let numberOfChunks = numberOfChunks else {
			return self
		}
		var file = self
		let chunkIndex = chunkResponse.partNumber - 1
		let chunkSize: Bytes
		let isLastChunk = chunkIndex == numberOfChunks - 1
		if !isLastChunk {
			chunkSize = Chunk.defaultChunkSize
		} else {
			chunkSize = file.filesize.remainderReportingOverflow(dividingBy: Chunk.defaultChunkSize).partialValue
		}
		let chunkOffset = Bytes(chunkIndex) * Chunk.defaultChunkSize
		let chunk = Chunk(chunkNumber: chunkResponse.partNumber,
						  fileURL: url,
						  uploadURL: chunkResponse.uploadUrl,
						  uploadIdentifier: chunkResponse.uploadId,
						  chunkSize: chunkSize,
						  byteOffset: chunkOffset)
		file.chunks.append(chunk)
		file.chunks.sort(by: { $0.chunkNumber < $1.chunkNumber })
		return file
	}
}
