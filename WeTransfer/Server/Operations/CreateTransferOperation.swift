//
//  CreateTransferOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

final class CreateTransferOperation: AsynchronousResultOperation<Transfer> {
	
	let transfer: Transfer
	
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
		WeTransfer.request(.createTransfer(), parameters: parameters) { result in
			switch result {
			case .success(let response):
				self.transfer.update(with: response.id, shortURL: response.shortenedUrl)
				self.finish(with: .success(self.transfer))
			case .failure(let error):
				self.finish(with: .failure(error))
			}
		}
	}
}
