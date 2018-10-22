//
//  AddFilesOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Operation responsible for adding files to the provided board object and on the server as well. When succeeded, the files will be updated with the appropriate data like identifiers and information about the chunks.
/// - Note: The files will be added to the provided board object when the operation has started executing
final class AddFilesOperation: ChainedAsynchronousResultOperation<Board, Board> {
	
	enum Error: Swift.Error, LocalizedError {
		/// Not all files or incorrect file data returned by server
		case incompleteFileDataReceived
		
		var localizedDescription: String {
			switch self {
			case .incompleteFileDataReceived:
				return "Server did not create the correct files"
			}
		}
	}
	
	/// The files to be added to the transfer if added during the initialization
	private var filesToAdd: [File]?
	
	/// Initializes the operation with a transfer object and array of files to add. When initalized as part of a chain after `CreateTransferOperation`, this operation can be initialized without any arguments
	///
	/// - Parameters:
	///   - transfer: Transfer object to add the files to
	///   - files: Files to be added to the transfer
	convenience init(board: Board, files: [File]) {
		self.init(input: board)
		filesToAdd = files
	}
	
	override func execute(_ board: Board) {
		if let newFiles = filesToAdd {
			board.add(newFiles)
		}
		let files = board.files.filter({ $0.identifier == nil })
		let parameters = AddFilesParameters(with: files)
		
		guard let identifier = board.identifier else {
			finish(with: .failure(WeTransfer.Error.transferNotYetCreated))
			return
		}
		
		WeTransfer.request(.addFiles(boardIdentifier: identifier), parameters: parameters.files) { [weak self] result in
			switch result {
			case .success(let responseFiles):
				
				var responseFilePool = Array(responseFiles)
				
				let updatedFiles: [File] = files.compactMap({ file in
					guard let responseFileIndex = responseFilePool.firstIndex(where: { $0.name == file.filename && $0.size == file.filesize }) else {
						return nil
					}
					let responseFile = responseFilePool.remove(at: responseFileIndex)
					file.update(with: responseFile.id,
								numberOfChunks: responseFile.multipart.partNumbers,
								chunkSize: responseFile.multipart.chunkSize,
								multipartUploadIdentifier: responseFile.multipart.id)
					return file
				})
				
				guard updatedFiles.count == files.count else {
					self?.finish(with: .failure(Error.incompleteFileDataReceived))
					return
				}
				self?.finish(with: .success(board))
			case .failure(let error):
				self?.finish(with: .failure(error))
			}
		}
	}
}
