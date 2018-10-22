//
//  CreateTransferOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Operation responsible for creating the transfer on the server and providing the given transfer object with an identifier and URL when succeeded.
/// This operation does not handle the requests necessary to add files to the server side transfer, which `AddFilesOperation` is responsible for
final class CreateBoardOperation: AsynchronousResultOperation<Board> {
	
	private let board: Board
	
	/// Initializes the operation with the necessary properties for a new board
	///
	/// - Parameters:
	///   - name: Name of the board to be created
	///   - description: Optional description of the board to be created
	convenience init(name: String, description: String?) {
		self.init(board: Board(name: name, description: description))
	}
	
	/// Initalizes the operation with a board to be created on the server
	///
	/// - Parameter board: Board object
	required init(board: Board) {
		self.board = board
		super.init()
	}
	
	override func execute() {
		guard board.identifier == nil else {
			finish(with: .success(board))
			return
		}

		let parameters = CreateBoardParameters(with: board)
		WeTransfer.request(.createBoard(), parameters: parameters) { [weak self] result in
			guard let self = self else {
				return
			}
			switch result {
			case .success(let response):
				self.board.update(with: response.id, shortURL: response.url)
				self.finish(with: .success(self.board))
			case .failure(let error):
				self.finish(with: .failure(error))
			}
		}
	}
}
