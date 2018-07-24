//
//  UploadFilesOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Handles the uploading of all files -- that are not uploaded yet -- in the provided transfer. Creates an operation queue with an `UploadFileOperation` for each file to be uploaded.
final class UploadFilesOperation: ChainedAsynchronousResultOperation<Transfer, Transfer>, URLSessionDataDelegate {
	
	/// Amount of bytes already sent
	private var bytesSent: Bytes = 0
	/// The total amount of bytes to be sent
	private var totalBytes: Bytes = 0
	
	/// The total progress for all files to be uploaded
	let progress = Progress(totalUnitCount: 1)
	
	/// Initializes the operation with a transfer. When initalized as part of a chain after `AddFilesOperation`, this operation can be initialized without any arguments
	///
	/// - Parameter transfer: Transfer object to upload files from
	convenience init(transfer: Transfer) {
		self.init(input: transfer)
	}
	
	override func execute(_ transfer: Transfer) {
		guard transfer.identifier != nil else {
			self.finish(with: .failure(WeTransfer.Error.transferNotYetCreated))
			return
		}
		
		let files = transfer.files.filter({ $0.isUploaded == false })
		
		guard !files.isEmpty else {
			self.finish(with: .failure(WeTransfer.Error.noFilesAvailable))
			return
		}
		
		totalBytes = files.reduce(0, { $0 + $1.filesize })

		// Each seperate files are handled in a queue
		let fileOperationQueue = OperationQueue()
		
		// OperationQueue that handles all chunks concurrently
		let chunkOperationQueue = OperationQueue()
		chunkOperationQueue.maxConcurrentOperationCount = 5
		
		// Seperate URLSession that handles the actual uploading and reports the upload progress
		let uploadSession = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
		progress.totalUnitCount = Int64(self.totalBytes)
		
		// Use the queue of the uploadSession to handle the progress
		uploadSession.delegateQueue.underlyingQueue?.async { [weak self] in
			guard let strongSelf = self else {
				return
			}
			strongSelf.progress.becomeCurrent(withPendingUnitCount: Int64(strongSelf.totalBytes))
		}
		
		let filesResultOperation = AsynchronousDependencyResultOperation<File>()
		
		let fileOperations = files.compactMap { file -> UploadFileOperation? in
			guard file.identifier != nil, file.multipartUploadIdentifier != nil else {
				// File may have been added while operations have created, fail silently
				return nil
			}
			let operation = UploadFileOperation(file: file, operationQueue: chunkOperationQueue, session: uploadSession)
			operation.onResult = { result in
				if case .success(let file) = result {
					file.isUploaded = true
				}
			}
			filesResultOperation.addDependency(operation)
			return operation
		}
		
		guard !fileOperations.isEmpty else {
			// No files to upload, fail
			self.finish(with: .failure(WeTransfer.Error.noFilesAvailable))
			return
		}
		
		filesResultOperation.onResult = { [weak self] result in
			uploadSession.delegateQueue.underlyingQueue?.async {
				self?.progress.resignCurrent()
			}
			switch result {
			case .success:
				self?.finish(with: .success(transfer))
			case .failure(let error):
				self?.finish(with: .failure(error))
			}
		}
		
		fileOperationQueue.addOperations(fileOperations + [filesResultOperation], waitUntilFinished: false)
	}
	
	// Use the didSendBodyData delegate method to update the upload progress
	func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
		self.bytesSent += UInt64(bytesSent)
		progress.completedUnitCount = Int64(self.bytesSent)
	}
}
