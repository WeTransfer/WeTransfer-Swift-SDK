//
//  AddFilesOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

struct AddFilesParameters: Encodable {
	
	struct Item: Encodable {
		let filename: String
		let filesize: UInt64
		let contentIdentifier: String
		let localIdentifier: String
		
		init(with file: File) {
			filename = file.filename
			filesize = file.filesize
			contentIdentifier = "file"
			localIdentifier = file.localIdentifier
		}
	}
	
	let items: [Item]
	
	init(with files: [File]) {
		items = files.map { file in
			return Item(with: file)
		}
	}
}

struct AddFilesResponse: Decodable {
	
	struct Meta: Decodable {
		let multipartParts: Int
		let multipartUploadId: String
	}
	
	let id: String
	let contentIdentifier: String
	let localIdentifier: String
	let meta: Meta
	let name: String
	let size: UInt64
	let uploadId: String
	let uploadExpiresAt: TimeInterval
}

class AddFilesOperation: ChainedAsynchronousResultOperation<Transfer, Transfer> {
	
	override func execute(_ transfer: Transfer) {
		let files = transfer.files.filter({ $0.identifier == nil })
		let parameters = AddFilesParameters(with: files)
		
		guard let identifier = transfer.identifier else {
			self.finish(with: .failure(WeTransfer.Error.transferNotYetCreated))
			return
		}
		
		WeTransfer.request(.addItems(transferIdentifier: identifier), parameters: parameters) { (result: Result<[AddFilesResponse]>) in
			switch result {
			case .success(let response):
				transfer.updateFiles(with: response)
				self.finish(with: .success(transfer))
			case .failure(let error):
				self.finish(with: .failure(error))
			}
		}
	}
}
