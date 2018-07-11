//
//  UploadFileOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Responsible for creating the necessary operations to create and upload chunks for the provided file. Uses the provided operation queue to handle created operations and the actual uploading is done with the provided URLSession
final class UploadFileOperation: AsynchronousResultOperation<File> {
	
	enum Error: Swift.Error {
		case noChunksAvailable
		case fileAlreadyUploaded
	}
	
	/// File to upload
	let file: File
	/// Queue to add the created operations to
	let operationQueue: OperationQueue
	/// URLSession handling the creation and actual uploading of the chunks
	let session: URLSession
	
	/// Initializes the operation with the necessary file, operation queue and session
	///
	/// - Parameters:
	///   - file: The file from which to create and upload the chunks
	///   - operationQueue: Operation queue to add the operations to
	///   - session: URLSession that should handle the actual uploading
	required init(file: File, operationQueue: OperationQueue, session: URLSession) {
		self.file = file
		self.operationQueue = operationQueue
		self.session = session
		super.init()
	}
	
	override func execute() {
		guard let numberOfChunks = file.numberOfChunks else {
			self.finish(with: .failure(Error.noChunksAvailable))
			return
		}
		
		let completeOperation = CompleteUploadOperation(file: file)

		let chunkOperations = (0..<numberOfChunks).reduce([Operation](), { (array, chunkIndex) in
			let urlOperation = CreateChunkOperation(file: file, chunkIndex: chunkIndex)
			let uploadOperation = UploadChunkOperation(session: session)
			uploadOperation.addDependency(urlOperation)
			completeOperation.addDependency(uploadOperation)
			return array + [urlOperation, uploadOperation]
		})
		
		completeOperation.onResult = { [weak self] result in
			self?.finish(with: result)
		}
		
		operationQueue.addOperations(chunkOperations + [completeOperation], waitUntilFinished: false)
	}
}
