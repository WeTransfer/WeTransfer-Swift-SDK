//
//  APIEndpoints.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Describes an endpoint to talk to the API with. Can be initialized with either a path or a URL.
/// - Note: When initalizing with a URL, the base URL wil be ignored when using the `url(with baseURL)` method
struct APIEndpoint {
	
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

	/// Returns the the final URL by either appending the path to the base URL or using the URL property in case the base URL should be ignored.
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

	init(method: HTTPMethod = .post, path: String, requiresAuthentication: Bool = true) {
		self.method = method
		self.path = path
		self.url = nil
		self.requiresAuthentication = requiresAuthentication
	}

	init(method: HTTPMethod = .post, url: URL, requiresAuthentication: Bool = true) {
		self.method = method
		self.url = url
		self.path = nil
		self.requiresAuthentication = requiresAuthentication
	}

	static func authorize() -> APIEndpoint {
		// Only request that doesn't require a jwt token to be set
		return APIEndpoint(path: "authorize", requiresAuthentication: false)
	}

	static func createTransfer() -> APIEndpoint {
		return APIEndpoint(path: "transfers")
	}

	static func addItems(transferIdentifier: String) -> APIEndpoint {
		return APIEndpoint(path: "transfers/\(transferIdentifier)/items")
	}

	static func requestUploadURL(fileIdentifier: String, chunkIndex: Int, multipartIdentifier: String) -> APIEndpoint {
		return APIEndpoint(method: .get, path: "files/\(fileIdentifier)/uploads/\(chunkIndex + 1)/\(multipartIdentifier)")
	}

	static func upload(url: URL) -> APIEndpoint {
		return APIEndpoint(method: .put, url: url)
	}

	static func completeUpload(fileIdentifier: String) -> APIEndpoint {
		return APIEndpoint(path: "files/\(fileIdentifier)/uploads/complete")
	}
}

extension APIEndpoint: Equatable {
	public static func == (lhs: APIEndpoint, rhs: APIEndpoint) -> Bool {
		return lhs.method == rhs.method && lhs.path == rhs.path && lhs.url == rhs.url
	}
}
