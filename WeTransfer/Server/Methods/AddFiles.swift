//
//  AddFiles.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {

	struct AddFilesRequestParameters: Encodable {

		struct Item: Encodable { // swiftlint:disable:this nesting
			let filename: String
			let filesize: UInt64
			let contentIdentifier: String
			let localIdentifier: String

			init(with file: File) {
				filename = file.filename
				filesize = file.filesize
				contentIdentifier = file.contentIdentifier
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

		struct Meta: Decodable { // swiftlint:disable:this nesting
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

	static func onlyAddFiles(_ files: [File], to transfer: Transfer, completion: @escaping (Result<Transfer>) -> Void) throws {
		guard let identifier = transfer.identifier else {
			throw Error.transferNotYetCreated
		}

		transfer.addFiles(files)

		let requestParameters = AddFilesRequestParameters(with: files)
		let data = try client.encoder.encode(requestParameters)

		try request(.addItems(transferIdentifier: identifier), data: data) { (result: Result<[AddFilesResponse]>) in
			switch result {
			case .success(let addedItemResponse):
				transfer.updateFiles(with: addedItemResponse)
				completion(.success(transfer))
			case .failure(let error):
				completion(.failure(error))
			}
		}

	}

	public static func addFiles(_ files: [File], to transfer: Transfer, completion: @escaping (Result<Transfer>) -> Void) throws {

		try onlyAddFiles(files, to: transfer, completion: { (result) in
			do {
				try addUploadUrls(to: transfer, completion: { (result) in
					switch result {
					case .success(let transfer):
						completion(.success(transfer))
					case .failure(let error):
						completion(.failure(error))
					}
				})
			} catch {
				completion(.failure(error))
			}
		})

	}

	struct AddUploadURLResponse: Decodable {
		let uploadUrl: URL
		let partNumber: Int
		let uploadId: String
		let uploadExpiresAt: TimeInterval
	}

	static func addUploadUrls(to transfer: Transfer, completion: @escaping (Result<Transfer>) -> Void) throws {
		guard transfer.identifier != nil else {
			throw Error.transferNotYetCreated
		}

		for (fileIndex, file) in transfer.files.enumerated() {
			guard let numberOfChunks = file.numberOfChunks,
				let fileIdenifier = file.identifier,
				let multipartUploadIdentifier = file.multipartUploadIdentifier else {
					continue
			}

			var tasksInProgress = [APIEndpoint]()
			var succeededTasks = [APIEndpoint]()

			for chunkIndex in 0..<numberOfChunks {
				let endpoint: APIEndpoint = .requestUploadURL(fileIdentifier: fileIdenifier, chunkIndex: chunkIndex, multipartIdentifier: multipartUploadIdentifier)
				tasksInProgress.append(endpoint)
				try request(endpoint, completion: { (result: Result<AddUploadURLResponse>) in
					if let index = tasksInProgress.index(of: endpoint) {
						tasksInProgress.remove(at: index)
					}
					switch result {
					case .success(let uploadUrlResponse):
						succeededTasks.append(endpoint)
						let file = transfer.files[fileIndex]
						transfer.updateFile(file, with: uploadUrlResponse)
						if tasksInProgress.isEmpty {
							completion(.success(transfer))
						}
					case .failure(let error):
						if tasksInProgress.isEmpty {
							if succeededTasks.isEmpty {
								completion(.failure(error))
							} else {
								completion(.success(transfer))
							}
						}
					}
				})
			}
		}
	}
}
