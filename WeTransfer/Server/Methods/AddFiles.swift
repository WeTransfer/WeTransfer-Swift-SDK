//
//  AddFiles.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {
	
	/// Adds the given files to the provided board object and on the server side as well. When succeeded the files will be updated with the appropriate data like identifiers and information about the chunks
	/// Creates a remote instance of the board when that has not happended yet
	///
	/// - Parameters:
	///   - files: File representations to be added to the transfer
	///   - board: Board object to add the files to
	///   - completion: Closure to be executed when request has completed
	///   - result: Result with either the updated transfer object or an error when something went wrong
	public static func add(_ files: [File], to board: Board, completion: @escaping (_ result: Result<Board>) -> Void) {
		let operation = AddFilesOperation(board: board, files: files)
		operation.onResult = { result in
			DispatchQueue.main.async {
				completion(result)
			}
		}
		
		// Externally create the board if not already in the queue
		if board.identifier == nil && client.operationQueue.operations.first(where: { $0 is CreateBoardOperation }) == nil {
			let createBoardOperation = CreateBoardOperation(board: board)
			operation.addDependency(createBoardOperation)
			client.operationQueue.addOperation(createBoardOperation)
		}
		
		// Add the latest AddFilesOperation in the queue as a dependency so all files are added in the correct order
		if let queuedAddFilesOperation = client.operationQueue.operations.last(where: { $0 is AddFilesOperation}) {
			operation.addDependency(queuedAddFilesOperation)
		}
		client.operationQueue.addOperation(operation)
	}
}
