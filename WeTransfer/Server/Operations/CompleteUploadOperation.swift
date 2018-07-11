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
	
	enum Error: Swift.Error {
		case fileNotCreatedYet
	}
	
	/// File to complete the uploading of
	let file: File
	
	/// Initializes the operation with a file to complete the upload for
	///
	/// - Parameter file: File struct for which to complete the upload for
	required init(file: File) {
		self.file = file
		super.init()
	}
	
	override func execute() {
		
		guard let fileIdentifier = file.identifier else {
			finish(with: .failure(Error.fileNotCreatedYet))
			return
		}
		
		let resultDependencies = dependencies.compactMap({ $0 as? AsynchronousResultOperation<Chunk> })
		let errors = resultDependencies.compactMap({ $0.result?.error })
		
		if let error = errors.last {
			finish(with: .failure(error))
			return
		}
		
		WeTransfer.request(.completeUpload(fileIdentifier: fileIdentifier)) { [weak self] result in
			if case .failure(let error) = result {
				self?.finish(with: .failure(error))
			} else {
				guard let file = self?.file else {
					return
				}
				self?.finish(with: .success(file))
			}
		}
	}
	
}
