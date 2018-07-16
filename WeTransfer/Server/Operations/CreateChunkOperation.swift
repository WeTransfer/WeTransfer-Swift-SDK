//
//  CreateChunkOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Creates a chunk of a file to be uploaded. Designed to be used right before `UploadChunkOperation`
final class CreateChunkOperation: AsynchronousResultOperation<Chunk> {
	
	enum Error: Swift.Error, LocalizedError {
		/// File has not been added to the transfer yet
		case fileNotYetAdded
		
		var localizedDescription: String {
			switch self {
			case .fileNotYetAdded:
				return "File has not been added to the transfer yet"
			}
		}
	}
	
	/// File to create chunk from
	private let file: File
	/// Index of chunk from file
	private let chunkIndex: Int
	
	/// Initalizes the operation with a file and an index of the chunk
	///
	/// - Parameters:
	///   - file: File struct of the file to create the chunk from
	///   - chunkIndex: Index of the chunk to be created
	required init(file: File, chunkIndex: Int) {
		self.file = file
		self.chunkIndex = chunkIndex
	}
	
	override func execute() {
		guard let fileIdentifier = file.identifier, let uploadIdentifier = file.multipartUploadIdentifier else {
			self.finish(with: .failure(Error.fileNotYetAdded))
			return
		}
		
		let endpoint: APIEndpoint = .requestUploadURL(fileIdentifier: fileIdentifier,
													  chunkIndex: chunkIndex,
													  multipartIdentifier: uploadIdentifier)
		WeTransfer.request(endpoint) { [weak self] result in
			switch result {
			case .failure(let error):
				self?.finish(with: .failure(error))
			case .success(let response):
				guard let file = self?.file else {
					return
				}
				// Chunks are locally referenced in a zero-based index. Subtract 1 from partNumber value
				let chunkIndex = response.partNumber - 1
				let chunk = Chunk(file: file, chunkIndex: chunkIndex, uploadURL: response.uploadUrl)
				self?.finish(with: .success(chunk))
			}
		}
	}
	
}
