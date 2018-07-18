//
//  AddFilesOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Operation responsible for adding files to the provided transfer object and on the server as well. When succeeded the files will be updated with the appropriate data like identifiers and information about the chunks.
/// - Note: The files will be added to the provided transfer object when the operation has started executing
final class AddFilesOperation: ChainedAsynchronousResultOperation<Transfer, Transfer> {
	
	/// The files to be added to the transfer if added during the initialization
	private var filesToAdd: [File]?
	
	/// Initializes the operation with a transfer object and array of files to add. When initalized as part of a chain after `CreateTransferOperation`, this operation can be initialized without any arguments
	///
	/// - Parameters:
	///   - transfer: Transfer object to add the files to
	///   - files: Files to be added to the transfer
	convenience init(transfer: Transfer, files: [File]) {
		self.init(input: transfer)
		filesToAdd = files
	}
	
	override func execute(_ transfer: Transfer) {
		if let newFiles = filesToAdd {
			transfer.add(newFiles)
		}
		let files = transfer.files.filter({ $0.identifier == nil })
		let parameters = AddFilesParameters(with: files)
		
		guard let identifier = transfer.identifier else {
			finish(with: .failure(WeTransfer.Error.transferNotYetCreated))
			return
		}
		
		WeTransfer.request(.addItems(transferIdentifier: identifier), parameters: parameters) { [weak self] result in
			switch result {
			case .success(let response):
				transfer.files.forEach({ file in
					guard let responseFile = response.first(where: {$0.localIdentifier == file.localIdentifier}) else {
						return
					}
					
					file.update(with: responseFile.id, numberOfChunks: responseFile.meta.multipartParts, multipartUploadIdentifier: responseFile.meta.multipartUploadId)
				})
				self?.finish(with: .success(transfer))
			case .failure(let error):
				self?.finish(with: .failure(error))
			}
		}
	}
}
