//
//  WeTransfer.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

final public class WeTransfer {
	
	public struct Configuration {
		public let APIKey: String
		public init(APIKey: String) {
			self.APIKey = APIKey
		}
	}
	
	public enum Error: Swift.Error {
		case notConfigured
		case notAuthorized
		case transferAlreadyCreated
	}
	let baseUrl: URL = URL(string: "https://dev.wetransfer.com/v1/")!
	
	private static let client = WeTransfer()
	
	private let decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}()
	
	private let encoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		return encoder
	}()
	
	private let urlSession: URLSession = {
		let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
		return session
	}()
	
	private var authenticationBearer: String?
	private(set) var configuration: Configuration?
}

extension WeTransfer {
	
	public static func configure(with configuration: Configuration) {
		client.configuration = configuration
	}
	
	public enum RequestError: Swift.Error {
		case invalidResponseData
		case authorizationFailed
	}
	
	enum HTTPMethod: String {
		case get = "GET"
		case post = "POST"
		case put = "PUT"
		case delete = "DELETE"
	}
	
	private class func createRequest(with path: String, method: HTTPMethod = .post, data: Data? = nil, expectsToken: Bool = true) throws -> URLRequest {
		// Check auth
		guard let configuration = client.configuration else {
			throw Error.notConfigured
		}
		guard !expectsToken || client.authenticationBearer != nil else {
			throw Error.notAuthorized
		}
		var request = URLRequest(url: client.baseUrl.appendingPathComponent(path))
		request.httpMethod = method.rawValue
		request.addValue(configuration.APIKey, forHTTPHeaderField: "x-api-key")
		if let token = client.authenticationBearer {
			request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}
		if let data = data {
			request.httpBody = data
		}
		return request
	}
	
	public enum APIMethod: String {
		case authorize
		case createTransfer = "transfers"
		case addItems = "items"
		case completeUpload = "upload/complete"
	}
	
	
	private class func request<T: Decodable>(_ method: APIMethod, httpMethod: HTTPMethod = .post, data: Data? = nil, expectsToken: Bool = true, completion: @escaping (Result<T>) -> Void) throws {
		try authorize { (result) in
			if let error = result.error {
				completion(.failure(error))
				return
			}
			let request: URLRequest
			do {
				request = try createRequest(with: method.rawValue, method: httpMethod, data: data, expectsToken: expectsToken)
			} catch {
				completion(.failure(error))
				return
			}
			let task = client.urlSession.dataTask(with: request, completionHandler: { (data, urlResponse, error) in
				do {
					if let error = error {
						print("error with request: \(method.rawValue)")
						throw error
					}
					guard let data = data else {
						throw RequestError.invalidResponseData
					}
					let response = try client.decoder.decode(T.self, from: data)
					completion(.success(response))
				} catch {
					completion(.failure(error))
				}
			})
			task.resume()
		}
	}
}

extension WeTransfer {
	
	private struct AuthorizeResponse: Decodable {
		let success: Bool
		let token: String?
	}
	
	public class func authorize(completion: @escaping (Result<String>) -> Void) throws {
		if let bearer = client.authenticationBearer {
			completion(.success(bearer))
			return
		}
		let request = try createRequest(with: APIMethod.authorize.rawValue, expectsToken: false)
		let task = client.urlSession.dataTask(with: request) { (data, urlResponse, error) in
			do {
				if let error = error {
					throw error
				}
				guard let data = data else {
					throw RequestError.invalidResponseData
				}
				let response = try client.decoder.decode(AuthorizeResponse.self, from: data)
				if let token = response.token, response.success {
					client.authenticationBearer = token
					completion(.success(token))
				} else {
					throw RequestError.authorizationFailed
				}
				
			} catch {
				completion(.failure(error))
			}
		}
		task.resume()
	}
}

extension WeTransfer {
	
	internal struct CreateTransferResponse: Decodable {
		let id: String
		let shortenedUrl: URL
	}
	
	public class func createTransfer(with transfer: Transfer, completion: @escaping (Result<Transfer>) -> Void) throws {
		guard transfer.identifier == nil else {
			throw Error.transferAlreadyCreated
		}
		
		let data = try client.encoder.encode(transfer)
		try request(.createTransfer, httpMethod: .post, data: data) { (result: Result<CreateTransferResponse>) in
			switch result {
			case .success(let createdTransfer):
				transfer.update(with: createdTransfer)
				completion(.success(transfer))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	//	class func addItems(_ items: [Transfer.Item], to transfer: Transfer, completionHandler: (Bool, TransferError?) -> Void) -> URLSessionTask {
	//		// Add items to transfer server side
	//		return transfer
	//	}
	//
	//	class func startTransfer(_ transfer: Transfer,  progressHandler progress: Progress?, completionHandler completion: (Bool, TransferError?) -> Void) -> URLSessionTask {
	//
	//	}
}
