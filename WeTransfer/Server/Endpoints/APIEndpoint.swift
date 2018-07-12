//
//  APIEndpoint.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Describes an endpoint to talk to the API with
struct APIEndpoint<Response: Decodable> {
	
	enum HTTPMethod: String {
		case get = "GET"
		case post = "POST"
		case put = "PUT"
		case delete = "DELETE"
	}
	
	let method: HTTPMethod
	let requiresAuthentication: Bool
	let path: String
	let responseType: Response.Type = Response.self
	
	/// Returns the the final URL by appending the path to the provided base URL
	///
	/// - Parameter baseURL: The base URL to append the path property to
	/// - Returns: URL appropriate for the endpoint
	func url(with baseURL: URL) -> URL {
		return baseURL.appendingPathComponent(path)
	}
	
	/// Creates an APIEndpoint with a path
	///
	/// - Parameters:
	///   - method: HTTPMethod to use for the endpoint
	///   - path: Relative path to be added to a base URL
	///   - requiresAuthentication: Whether this endpoint requires authentication headers to be sent
	init(method: HTTPMethod, path: String, requiresAuthentication: Bool = true) {
		self.method = method
		self.path = path
		self.requiresAuthentication = requiresAuthentication
	}
}
