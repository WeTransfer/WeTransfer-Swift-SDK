//
//  CreateTransfer.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {
	
	struct CreateTransferRequestParameters: Encodable {
		let name: String
		let description: String?
		
		init(with transfer: Transfer) {
			name = transfer.name
			description = transfer.description
		}
	}
	
	struct CreateTransferResponse: Decodable {
		let id: String
		let shortenedUrl: URL
	}
	
	public static func createTransfer(with transfer: Transfer, completion: @escaping (Result<Transfer>) -> Void) throws {
		guard transfer.identifier == nil else {
			throw Error.transferAlreadyCreated
		}
		
		let requestParameters = CreateTransferRequestParameters(with: transfer)
		let data = try client.encoder.encode(requestParameters)
		
		try request(.createTransfer(), data: data) { (result: Result<CreateTransferResponse>) in
			switch result {
			case .success(let createdTransferResponse):
				transfer.update(with: createdTransferResponse)
				if transfer.files.isEmpty {
					completion(.success(transfer))
				} else {
					do {
						try addFiles(transfer.files, to: transfer, completion: completion)
					} catch {
						completion(.failure(error))
					}
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
}
