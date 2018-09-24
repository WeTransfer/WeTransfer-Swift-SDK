//
//  CompleteUploadOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Completes the upload of each file in a transfer. Typically used in `UploadFileOperation` after all the file's chunks have been uploaded
final class CompleteUploadOperation: AsynchronousResultOperation<File> {
	
	enum Error: Swift.Error, LocalizedError {
		/// File has not been added to the transfer yet
		case fileNotYetAdded
		
		var localizedDescription: String {
			switch self {
			case .fileNotYetAdded:
				return "File has not been added to the transfer yet"
			}
		}
	}
	
	/// File to complete the uploading of
	private let file: File
	
	/// Initializes the operation with a file to complete the upload for
	///
	/// - Parameter file: File struct for which to complete the upload for
	required init(file: File) {
		self.file = file
		super.init()
	}
	
	override func execute() {
		
		guard let fileIdentifier = file.identifier else {
			finish(with: .failure(Error.fileNotYetAdded))
			return
		}
		
		let resultDependencies = dependencies.compactMap({ $0 as? AsynchronousResultOperation<Chunk> })
		let errors = resultDependencies.compactMap({ $0.result?.error })
		
		if let error = errors.last {
			finish(with: .failure(error))
			return
		}
		
		WeTransfer.request(.completeUpload(fileIdentifier: fileIdentifier)) { [weak self] result in
			guard let strongSelf = self else {
				return
			}
			switch result {
			case .failure(let error):
				strongSelf.finish(with: .failure(error))
			case .success(let response):
				guard response.ok else {
					strongSelf.finish(with: .failure(WeTransfer.RequestError.serverError(errorMessage: response.message, httpCode: nil)))
					return
				}
				strongSelf.finish(with: .success(strongSelf.file))
			}
		}
	}
	
}
