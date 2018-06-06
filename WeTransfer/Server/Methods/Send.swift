//
//  Send.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {

	public enum State {
		/// Upload has started, track progress with progress object
		case started(Progress)
		/// Transfer is created server side, share url is now available
		case created(Transfer)
		/// Transfer is completed
		case completed(Transfer)
		/// Transfer failed due to provided error
		case failed(Swift.Error)
	}

	public static func send(_ transfer: Transfer, stateChanged: @escaping (State) -> Void) {
		let operation = UploadFilesOperation(input: transfer)
		if transfer.identifier != nil {
			stateChanged(.created(transfer))
			stateChanged(.started(operation.progress))
		}
		operation.onResult = { result in
			switch result {
			case .failure(let error):
				stateChanged(.failed(error))
			case .success(let transfer):
				stateChanged(.completed(transfer))
			}
		}
		client.operationQueue.addOperation(operation)
	}
}
