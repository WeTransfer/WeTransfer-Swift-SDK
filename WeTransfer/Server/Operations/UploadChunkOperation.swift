//
//  UploadChunkOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Uploads the chunk that resulted from the dependant `CreateChunkOperation`. The uploading is handled by the provided `URLSession`
final class UploadChunkOperation: ChainedAsynchronousResultOperation<Chunk, Chunk> {
	
	enum Error: Swift.Error, LocalizedError {
		/// No chunk data available. File at URL might be inaccessible
		case noChunkDataAvailable
		/// Upload did not succeed
		case uploadFailed
		
		var localizedDescription: String {
			switch self {
			case .noChunkDataAvailable:
				return "No chunk data available. File at URL might be inaccessible"
			case .uploadFailed:
				return "Chunk Upload did not succeed"
			}
		}
	}
	
	/// URLSession handling the creation and actual uploading of the chunk
	let session: URLSession
	
	/// Initializes the operation with a session which handles the actual uploading part
	///
	/// - Parameter session: `URLSession` that should create and be responsible of the actual uploading part
	required init(session: URLSession) {
		self.session = session
		super.init()
	}
	
	override func execute(_ chunk: Chunk) {
		guard let data = try? Data(from: chunk) else {
			self.finish(with: .failure(Error.noChunkDataAvailable))
			return
		}

		var urlRequest = URLRequest(url: chunk.uploadURL)
		urlRequest.httpMethod = "PUT"
		let task = self.session.uploadTask(with: urlRequest, from: data) { [weak self] (_, urlResponse, error) in
			if let error = error {
				self?.finish(with: .failure(error))
				return
			}
			if let response = urlResponse as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
				self?.finish(with: .failure(Error.uploadFailed))
				return
			}
			self?.finish(with: .success(chunk))
		}
		task.resume()
	}
}
