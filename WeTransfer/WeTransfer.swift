//
//  WeTransfer.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public class WeTransfer {

	static var client: APIClient = APIClient()
}

extension WeTransfer {

	public enum Error: Swift.Error {
		case notConfigured
		case notAuthorized
		case transferAlreadyCreated
		case transferNotYetCreated
		case noFilesAvailable
	}

	public struct Configuration {
		public let APIKey: String
		public let baseURL: URL

		public init(APIKey: String, baseURL: URL? = nil) {
			// swiftlint:disable force_unwrapping
			self.baseURL = baseURL ?? URL(string: "https://dev.wetransfer.com/v1/")!
			self.APIKey = APIKey
		}
	}

	public static func configure(with configuration: Configuration) {
		client.apiKey = configuration.APIKey
		client.baseURL = configuration.baseURL
	}
}

extension WeTransfer {

	@discardableResult
	public static func sendTransfer(named name: String, files urls: [URL], stateChanged: @escaping (State) -> Void) -> Transfer? {
		
		// Create the transfer model
		let files = urls.compactMap { url in
			return File(url: url)
		}
		let transfer = Transfer(name: name, description: nil, files: files)
		
		// Create transfer on server
		let creationOperation = CreateTransferOperation(transfer: transfer)
		
		// Add files to the transfer
		let addFilesOperation = AddFilesOperation()
		
		// Upload all files from the chunks
		let uploadFilesOperation = UploadFilesOperation()
		
		// Handle transfer created result
		creationOperation.onResult = { result in
			if case .success(let transfer) = result {
				stateChanged(.created(transfer))
			}
		}
		
		// When all files are ready for upload
		addFilesOperation.onResult = { result in
			if case .success = result {
				stateChanged(.started(uploadFilesOperation.progress))
			}
		}
		
		// Perform all operations in a chain
		let operations = [creationOperation, addFilesOperation, uploadFilesOperation].chained()
		client.operationQueue.addOperations(operations, waitUntilFinished: false)
		
		uploadFilesOperation.onResult = { result in
			switch result {
			case .failure(let error):
				stateChanged(.failed(error))
			case .success(let transfer):
				stateChanged(.completed(transfer))
			}
		}
		
		return transfer
	}
}
