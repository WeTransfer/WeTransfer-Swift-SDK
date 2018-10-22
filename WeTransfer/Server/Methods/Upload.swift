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
	public enum State<T> {
		/// Object is created server side, in case of Board now has url available
		case created(T)
		/// Upload has started, track progress with progress object
		case uploading(Progress)
		/// Transfer is completed
		case completed(T)
		/// Transfer failed due to provided error
		case failed(Swift.Error)
	}

	/// Uploads the files of the provided transfer, assuming it's created on the server and has files to be uploaded
	///
	/// - Parameters:
	///   - transfer: The Transfer object to be sent
	///   - stateChanged: Enum describing the current transfer's state. See the `State` enum description for more details for each state
	public static func upload(_ transfer: Transfer, stateChanged: @escaping (State<Transfer>) -> Void) {
		
		let changeState = { result in
			DispatchQueue.main.async {
				stateChanged(result)
			}
		}
		
		let uploadOperation = UploadFilesOperation(container: transfer)
		changeState(.uploading(uploadOperation.progress))
		
		let finalizeOperation = FinalizeTransferOperation()
		
		finalizeOperation.onResult = { result in
			switch result {
			case .failure(let error):
				changeState(.failed(error))
			case .success(let transfer):
				changeState(.completed(transfer))
			}
		}
		
		let operations = [uploadOperation, finalizeOperation].chained()
		client.operationQueue.addOperations(operations, waitUntilFinished: false)
	}
	
	/// Uploads the files of the provided board, assuming it's created on the server and has files to be uploaded
	///
	/// - Parameters:
	///   - board: The Board object to upload files from
	///   - stateChanged: Enum describing the state of the upload process. See the `State` enum description for more details for each state
	public static func upload(_ board: Board, stateChanged: @escaping (State<Board>) -> Void) {
		
		let changeState = { result in
			DispatchQueue.main.async {
				stateChanged(result)
			}
		}
		
		let operation = UploadFilesOperation(container: board)
		changeState(.uploading(operation.progress))
		
		operation.onResult = { result in
			switch result {
			case .failure(let error):
				changeState(.failed(error))
			case .success(let board):
				changeState(.completed(board))
			}
		}
		client.operationQueue.addOperation(operation)
	}
}
