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
	
	enum Error: Swift.Error, LocalizedError {
		/// File has no chunks to upload
		case noChunksAvailable
		
		var localizedDescription: String {
			switch self {
			case .noChunksAvailable:
				return "File has no chunks to upload"
			}
		}
	}
	
	/// File to upload
	private let file: File
	/// Queue to add the created operations to
	private let operationQueue: OperationQueue
	/// URLSession handling the creation and actual uploading of the chunks
	private let session: URLSession
	
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
	
	/// Creates the necessary operations for each chunk to be created and uploaded, with the create operation being chained to the upload operation so they happen subsequently. All upload operations are then added as a dependency to the provided complete operation.
	///
	/// - Parameter completeOperation: Operation depending on all upload operations. Should only be executed when all chunk operations have finished
	/// - Returns: An array of chunk operations, whith the each pair of create and upload operations being chained
	private func chainedChunkOperations(with completeOperation: CompleteUploadOperation) -> [Operation] {
		guard let numberOfChunks = file.numberOfChunks else {
			return []
		}
		var operations = [Operation]()
		for chunkIndex in 0..<numberOfChunks {
			let createOperation = CreateChunkOperation(file: file, chunkIndex: chunkIndex)
			let uploadOperation = UploadChunkOperation(session: session)
			operations.append(contentsOf: [createOperation, uploadOperation].chained())
			
			completeOperation.addDependency(uploadOperation)
		}
		return operations
	}
	
	override func execute() {
		guard file.numberOfChunks != nil else {
			self.finish(with: .failure(Error.noChunksAvailable))
			return
		}
		
		let completeOperation = CompleteUploadOperation(file: file)

		let chunkOperations = chainedChunkOperations(with: completeOperation)
		
		completeOperation.onResult = { [weak self] result in
			self?.finish(with: result)
		}
		
		operationQueue.addOperations(chunkOperations + [completeOperation], waitUntilFinished: false)
	}
}
