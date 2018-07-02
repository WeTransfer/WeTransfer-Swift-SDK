//
//  CreateChunkOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

class CreateChunkOperation: AsynchronousResultOperation<Chunk> {
	
	enum Error: Swift.Error {
		case fileNotYetAdded
	}
	
	let file: File
	let chunkIndex: Int
	
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
		WeTransfer.request(endpoint) { (result: Result<AddUploadURLResponse>) in
			switch result {
			case .failure(let error):
				self.finish(with: .failure(error))
			case .success(let response):
				let chunk = Chunk(file: self.file, response: response)
				self.finish(with: .success(chunk))
			}
		}
	}
	
}
