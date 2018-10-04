//
//  CreateTransferOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Operation responsible for creating the transfer on the server and providing the given transfer object with an identifier and URL when succeeded.
/// This operation does not handle the requests necessary to add files to the server side transfer, which `AddFilesOperation` is responsible for
final class CreateTransferOperation: AsynchronousResultOperation<Transfer> {
	
	let message: String
	let fileURLs: [URL]
	
	/// Initalized the operation with the necessary parameters for a transfer
	///
	/// - Parameter transfer: Transfer object with optionally some files already added
	required init(message: String, fileURLs: [URL]) {
		self.message = message
		self.fileURLs = fileURLs
		super.init()
	}
	
	override func execute() {
		let files: [File]
		do {
			files = try fileURLs.map({ try File(url: $0) })
		} catch {
			// Fail when any of the files failed to create
			finish(with: .failure(error))
			return
		}
		
		let parameters = CreateTransferParameters(message: message, files: files)
		WeTransfer.request(.createTransfer(), parameters: parameters) { [weak self] result in
			guard let self = self else {
				return
			}
			switch result {
			case .success(let response):
				let updatedFiles: [File] = zip(response.files, files).map({ (files) in
					let (responseFile, file) = files
					file.update(with: response.id, numberOfChunks: responseFile.multipart.partNumbers, multipartUploadIdentifier: nil)
					return file
				})
				let transfer = Transfer(identifier: response.id, message: parameters.message, files: updatedFiles)
				self.finish(with: .success(transfer))
			case .failure(let error):
				self.finish(with: .failure(error))
			}
		}
	}
}
