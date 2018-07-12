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
	
	let transfer: Transfer
	
	/// Initalized the operation with a transfer object
	///
	/// - Parameter transfer: Transfer object with optionally some files already added
	required init(transfer: Transfer) {
		self.transfer = transfer
		super.init()
	}
	
	override func execute() {
		guard transfer.identifier == nil else {
			self.finish(with: .failure(WeTransfer.Error.transferAlreadyCreated))
			return
		}
		
		let parameters = CreateTransferParameters(with: transfer)
		WeTransfer.request(.createTransfer(), parameters: parameters) { [weak self] result in
			switch result {
			case .success(let response):
				if let transfer = self?.transfer {
					transfer.update(with: response.id, shortURL: response.shortenedUrl)
					self?.finish(with: .success(transfer))
				}
			case .failure(let error):
				self?.finish(with: .failure(error))
			}
		}
	}
}
