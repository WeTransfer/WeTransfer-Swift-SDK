//
//  CreateTransfer.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {

	/// Creates a board on the server and provides the given transfer object with an identifier and URL when succceeded.
	///
	/// - Parameters:
	///   - board: Local instance of the board to be created on the server
	///   - completion: Closure that will be executed when the request or requests have finished
	///   - result: Result with either the updated transfer object or an error when something went wrong
	static func createExternalBoard(_ board: Board, completion: @escaping (_ result: Result<Board>) -> Void) {
		
		let callCompletion = { result in
			DispatchQueue.main.async {
				completion(result)
			}
		}

		let creationOperation = CreateBoardOperation(board: board)
		
		creationOperation.onResult = callCompletion
		client.operationQueue.addOperation(creationOperation)
	}
}
