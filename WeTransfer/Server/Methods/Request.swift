//
//  Request.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {

	public enum RequestError: Swift.Error {
		case invalidResponseData
		case authorizationFailed
		case serverError(errorMessage: String)
	}

	struct ErrorResponse: Decodable {
		let success: Bool?
		let message: String
	}

	static func parseErrorResponse(_ data: Data?) -> Swift.Error? {
		guard let data = data,
			let errorResponse = try? client.decoder.decode(ErrorResponse.self, from: data),
			errorResponse.success != true else {
				return nil
		}
		return RequestError.serverError(errorMessage: errorResponse.message)
	}

	static func request<T: Decodable>(_ endpoint: APIEndpoint, data: Data? = nil, needsToken: Bool = true, completion: @escaping (Result<T>) -> Void) throws {
		try authorize { (result) in
			if let error = result.error {
				completion(.failure(error))
				return
			}
			let request: URLRequest
			do {
				request = try client.createRequest(endpoint, data: data, needsToken: needsToken)
			} catch {
				completion(.failure(error))
				return
			}

			let task = client.urlSession.dataTask(with: request, completionHandler: { (data, _, error) in
				do {
					if let error = error {
						throw error
					}
					guard let data = data else {
						throw RequestError.invalidResponseData
					}
					let response = try client.decoder.decode(T.self, from: data)
					completion(.success(response))
				} catch {
					let serverError = parseErrorResponse(data) ?? error
					completion(.failure(serverError))
				}
			})
			task.resume()
		}
	}
}
