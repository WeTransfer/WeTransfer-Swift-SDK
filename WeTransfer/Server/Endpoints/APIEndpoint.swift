//
//  APIEndpoint.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Describes an endpoint to talk to the API with. Can be initialized with either a path or a URL.
/// - Note: When initalizing with a URL, the base URL wil be ignored when using the `url(with baseURL)` method
struct APIEndpoint<Response: Decodable> {
	
	enum HTTPMethod: String {
		case get = "GET"
		case post = "POST"
		case put = "PUT"
		case delete = "DELETE"
	}
	
	let method: HTTPMethod
	let requiresAuthentication: Bool
	let path: String?
	let url: URL?
	let responseType: Response.Type = Response.self
	
	/// Returns the the final URL by either appending the path to the provided base URL or using the URL property in case the base URL should be ignored.
	///
	/// - Parameter baseURL: The base URL to append the path property to
	/// - Returns: URL appropriate for the endpoint
	func url(with baseURL: URL) -> URL? {
		if let url = url {
			return url
		}
		guard let path = path else {
			return nil
		}
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
		self.url = nil
		self.requiresAuthentication = requiresAuthentication
	}
	
	/// Creates an APIEndpoint with a fixed URL, ignoring any usage of a base URL
	///
	/// - Parameters:
	///   - method: HTTPMethod to use for the endpoint
	///   - url: Full URL to call the endpoint with. Base URL will be ignored when querying the URL
	///   - requiresAuthentication: Wheter this endpoint required authentication headers to be sent
	init(method: HTTPMethod, url: URL, requiresAuthentication: Bool = true) {
		self.method = method
		self.url = url
		self.path = nil
		self.requiresAuthentication = requiresAuthentication
	}
}
