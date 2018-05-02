//
//  WeTransfer.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public struct WeTransfer {
	
	static var client: APIClient = APIClient(baseURL: URL(string: "https://dev.wetransfer.com/v1/")!)
}

extension WeTransfer {
	
	public enum Error: Swift.Error {
		case notConfigured
		case notAuthorized
		case transferAlreadyCreated
		case transferNotYetCreated
	}
	
	public struct Configuration {
		public let APIKey: String
		public init(APIKey: String) {
			self.APIKey = APIKey
		}
	}
	
	public static func configure(with configuration: Configuration) {
		client.apiKey = configuration.APIKey
	}
}

extension WeTransfer {
	
	public static func sendTransfer(named name: String, files urls: [URL], stateChanged: @escaping (State) -> Void) throws {
	
		// Create transfer
		let files = urls.compactMap { url in
			return File(url: url)
		}
		let transfer = Transfer(name: name, description: nil, files: files)
		try createTransfer(with: transfer) { result in
			
		}
		
		try send(transfer, stateChanged: stateChanged)
	}
}
