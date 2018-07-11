//
//  UploadFileOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

final class UploadFileOperation: AsynchronousResultOperation<File> {
	
	enum Error: Swift.Error {
		case noChunksAvailable
		case fileAlreadyUploaded
	}
	
	let file: File
	let operationQueue: OperationQueue
	let session: URLSession
	
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
