//
//  FinalizeTransferOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 08/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Finalizes the provided Transfer after all files have been uploaded. The Transfer object will be updated with a URL as a result.
final class FinalizeTransferOperation: ChainedAsynchronousResultOperation<Transfer, Transfer> {
	
	/// Initializes the operation with a transfer. When initalized as part of a chain this operation can be initialized without any arguments
	///
	/// - Parameter container: Transfer object to finalize on the server
	convenience init(container: Transfer) {
		self.init(input: container)
	}
	
	override func execute(_ transfer: Transfer) {
		guard transfer.shortURL == nil else {
			finish(with: .failure(WeTransfer.Error.transferAlreadyFinalized))
			return
		}
		
		guard let identifier = transfer.identifier else {
			finish(with: .failure(WeTransfer.Error.transferNotYetCreated))
			return
		}
		
		WeTransfer.request(.finalizeTransfer(transferIdentifier: identifier)) { [weak self] result in
			switch result {
			case .success(let response):
				transfer.update(with: response.url)
				self?.finish(with: .success(transfer))
			case .failure(let error):
				self?.finish(with: .failure(error))
			}
		}
	}
	
}
