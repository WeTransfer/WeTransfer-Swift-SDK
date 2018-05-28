//
//  APIEndpoints.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case delete = "DELETE"
}

public struct APIEndpoint {

	let method: HTTPMethod
	let path: String?
	let url: URL?

	func url(with baseURL: URL?) -> URL? {
		if let url = url {
			return url
		}
		guard let path = path else {
			return nil
		}
		return baseURL?.appendingPathComponent(path)
	}

	init(method: HTTPMethod = .post, path: String) {
		self.method = method
		self.path = path
		self.url = nil
	}

	init(method: HTTPMethod = .post, url: URL) {
		self.method = method
		self.url = url
		self.path = nil
	}

	static func authorize() -> APIEndpoint {
		return APIEndpoint(path: "authorize")
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
