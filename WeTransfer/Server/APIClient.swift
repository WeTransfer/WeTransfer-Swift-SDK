//
//  APIClient.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public class APIClient {
	internal(set) var apiKey: String?
	internal(set) var baseURL: URL?
	var authenticationBearer: String?
	
	let urlSession: URLSession = {
		let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
		return session
	}()
	
	let decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}()
	
	let encoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		return encoder
	}()
}

extension APIClient {
	
	public enum Error: Swift.Error {
		case notConfigured
		case notAuthorized
		case transferAlreadyCreated
		case transferNotYetCreated
	}
	
	func createRequest(_ endpoint: APIEndpoint, data: Data? = nil, needsToken: Bool = true) throws -> URLRequest {
		// Check auth
		guard let apiKey = apiKey else {
			throw Error.notConfigured
		}
		guard !needsToken || authenticationBearer != nil else {
			throw Error.notAuthorized
		}
		guard let url = endpoint.url(with: baseURL) else {
			throw Error.notConfigured
		}
		var request = URLRequest(url: url)
		request.httpMethod = endpoint.method.rawValue
		request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
		if let token = authenticationBearer {
			request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}
		if let data = data {
			request.httpBody = data
		}
		return request
	}
	
}
