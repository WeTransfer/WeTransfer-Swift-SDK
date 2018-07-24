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
	
	private let transfer: Transfer
	
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
			guard let strongSelf = self else {
				return
			}
			switch result {
			case .success(let response):
				strongSelf.transfer.update(with: response.id, shortURL: response.shortenedUrl)
				strongSelf.finish(with: .success(strongSelf.transfer))
			case .failure(let error):
				strongSelf.finish(with: .failure(error))
			}
		}
	}
}
