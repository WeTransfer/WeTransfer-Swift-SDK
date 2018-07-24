//
//  APIClient.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Holds the local state for communicating with the API.
/// Handles the creation of the appropriate requests, and holds any request-associated classes like the decoder and encoder
final class APIClient {
	/// The API key used for each request
	var apiKey: String?
	/// URL to point to the server to. Each endpoint appends its path to the base URL
	var baseURL: URL?
	
	/// Handles the storage of the authentication bearer and adds authentication headers to requests
	let authenticator = Authenticator()
	
	/// Main URL session used by for all requests
	let urlSession: URLSession = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
	
	/// Main operation queue handling all operations concurrently
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
		
		var request = URLRequest(endpoint: endpoint, baseURL: baseURL, apiKey: apiKey)
		request = authenticator.authenticatedRequest(from: request)
		
		if let data = data {
			request.httpBody = data
		}
		return request
	}
}

fileprivate extension URLRequest {
	/// Initializes a URLRequest instance from and endpoint
	///
	/// - Parameters:
	///   - endpoint: Endpoint describing the url and HTTP method
	///   - baseURL: URL to append the endpoint's path to
	///   - apiKey: API key to add to the headers
	init<Response>(endpoint: APIEndpoint<Response>, baseURL: URL, apiKey: String) {
		self.init(url: endpoint.url(with: baseURL))
		httpMethod = endpoint.method.rawValue
		addValue(apiKey, forHTTPHeaderField: "x-api-key")
	}
}
