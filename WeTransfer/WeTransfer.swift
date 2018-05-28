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
	}
	
	public struct Configuration {
		public let APIKey: String
		public let baseURL: URL
		
		public init(APIKey: String, baseURL: URL? = nil) {
			self.baseURL = baseURL ?? URL(string: "https://dev.wetransfer.com/v1/")! // swiftlint:disable:this force_unwrapping
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
	
		// Create transfer
		let files = urls.compactMap { url in
			return File(url: url)
		}
		let transfer = Transfer(name: name, description: nil, files: files)
		do {
			try createTransfer(with: transfer) { result in
				switch result {
				case .failure(let error):
					stateChanged(.failed(error))
				case .success(let transfer):
					send(transfer, stateChanged: stateChanged)
				}
			}
		} catch {
			stateChanged(.failed(error))
			return nil
		}
		return transfer
	}
}
