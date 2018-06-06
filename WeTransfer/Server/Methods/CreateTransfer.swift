//
//  CreateTransfer.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {

	public static func createTransfer(with transfer: Transfer, completion: @escaping (Result<Transfer>) -> Void) {

		let creationOperation = CreateTransferOperation(transfer: transfer)
		
		guard !transfer.files.isEmpty else {
			creationOperation.onResult = completion
			client.operationQueue.addOperation(creationOperation)
			return
		}
		
		let addFilesOperation = AddFilesOperation()
		addFilesOperation.onResult = completion
		let operations = [creationOperation, addFilesOperation].chained()
		
		client.operationQueue.addOperations(operations, waitUntilFinished: false)
	}
}
