//
//  Upload.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {
	
	/// State of current transfer
	public enum State {
		/// Transfer is created server side, share url is now available
		case created(Transfer)
		/// Upload has started, track progress with progress object
		case uploading(Progress)
		/// Transfer is completed
		case completed(Transfer)
		/// Transfer failed due to provided error
		case failed(Swift.Error)
	}

	/// Uploads the files of the provided transfer, assuming it's created on the server and has files to be uploaded
	///
	/// - Parameters:
	///   - transfer: The Transfer object to be sent
	///   - stateChanged: Enum describing the current transfer's state. See the `State` enum description for more details for each state
	public static func upload(_ transfer: Transfer, stateChanged: @escaping (State) -> Void) {
		
		let changeState = { result in
			DispatchQueue.main.async {
				stateChanged(result)
			}
		}
		
		let operation = UploadFilesOperation(transfer: transfer)
		if transfer.identifier != nil {
			changeState(.created(transfer))
			changeState(.uploading(operation.progress))
		}
		operation.onResult = { result in
			switch result {
			case .failure(let error):
				changeState(.failed(error))
			case .success(let transfer):
				changeState(.completed(transfer))
			}
		}
		client.operationQueue.addOperation(operation)
	}
}
