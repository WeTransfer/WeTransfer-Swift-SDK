//
//  AddFiles.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {
	
	public static func addFiles(_ files: [File], to transfer: Transfer, completion: @escaping (Result<Transfer>) -> Void) {
		transfer.addFiles(files)
		let operation = AddFilesOperation(input: transfer)
		operation.onResult = completion
		client.operationQueue.addOperation(operation)
	}
}
