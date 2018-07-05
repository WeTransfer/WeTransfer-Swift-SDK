//
//  AddFilesOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

final class AddFilesOperation: ChainedAsynchronousResultOperation<Transfer, Transfer> {
	
	var filesToAdd: [File]?
	
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
			self.finish(with: .failure(WeTransfer.Error.transferNotYetCreated))
			return
		}
		
		WeTransfer.request(.addItems(transferIdentifier: identifier), parameters: parameters) { result in
			switch result {
			case .success(let response):
				transfer.updateFiles(with: response)
				self.finish(with: .success(transfer))
			case .failure(let error):
				self.finish(with: .failure(error))
			}
		}
	}
}
