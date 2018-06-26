//
//  AddFiles.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {
	
	/// Adds the given files to the provided transfer object and on the server side as well. When succeeded the files will be updated with the appropriate data like identifiers and information about the chunks
	///
	/// - Parameters:
	///   - files: File representations to be added to the transfer
	///   - transfer: Transfer object to add the files to
	///   - completion: Closure to be executed when request has completed
	///   - result: Result with either the updated transfer object or an error when something went wrong
	public static func addFiles(_ files: [File], to transfer: Transfer, completion: @escaping (_ result: Result<Transfer>) -> Void) {
		transfer.add(files)
		let operation = AddFilesOperation(input: transfer)
		operation.onResult = { result in
			DispatchQueue.main.async {
				completion(result)
			}
		}
		client.operationQueue.addOperation(operation)
	}
}
