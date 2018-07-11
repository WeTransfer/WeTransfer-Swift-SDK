//
//  APIClient.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Holds the local state for communicating with the API
/// Handles the creation of the appropriate requests, and holds any request-associated classes like the decoder and encoder
final class APIClient {
	var apiKey: String?
	var baseURL: URL?
	
	let authenticator = Authenticator()
	
	let urlSession: URLSession = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
	
	let operationQueue: OperationQueue = OperationQueue()
	
	/// Used to decode all json repsonses
	let decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}()
	
	/// Used to encode all parameters to json
	let encoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		return encoder
	}()
}

extension APIClient {
	
	/// Creates a URLRequest from an enpoint and optionally data to send along
	///
	/// - Parameters:
	///   - endpoint: Endpoint describing the url and HTTP method
	///   - data: Optional data to add to the request body
	/// - Returns: URLRequest pointing to URL with appropriate HTTP method set
	/// - Throws: `WeTransfer.Error` when not configured or not authorized
	func createRequest<Response>(_ endpoint: APIEndpoint<Response>, data: Data? = nil) throws -> URLRequest {
		guard let apiKey = apiKey, let baseURL = baseURL else {
			throw WeTransfer.Error.notConfigured
		}
		
		var request = try URLRequest(endpoint: endpoint, baseURL: baseURL, apiKey: apiKey)
		request = authenticator.authenticatedRequest(from: request)
		
		if let data = data {
			request.httpBody = data
		}
		return request
	}
}

fileprivate extension URLRequest {
	init<Response>(endpoint: APIEndpoint<Response>, baseURL: URL, apiKey: String) throws {
		self.init(url: endpoint.url(with: baseURL))
		httpMethod = endpoint.method.rawValue
		addValue(apiKey, forHTTPHeaderField: "x-api-key")
	}
}
