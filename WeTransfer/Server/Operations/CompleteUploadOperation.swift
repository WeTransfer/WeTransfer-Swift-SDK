//
//  CompleteUploadOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

struct CompleteTransferResponse: Decodable {
	let ok: Bool // swiftlint:disable:this identifier_name
	let message: String
}

class CompleteUploadOperation: AsynchronousResultOperation<File> {
	
	enum Error: Swift.Error {
		case fileNotCreatedYet
	}
	
	let file: File
	
	init(file: File) {
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
		
		WeTransfer.request(.completeUpload(fileIdentifier: fileIdentifier)) { (result: Result<CompleteTransferResponse>) in
			if case .failure(let error) = result {
				self.finish(with: .failure(error))
			} else {
				self.finish(with: .success(self.file))
			}
		}
	}
	
}
