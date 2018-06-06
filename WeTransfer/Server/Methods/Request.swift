//
//  Request.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {

	public enum RequestError: Swift.Error, LocalizedError {
		case invalidResponseData
		case authorizationFailed
		case serverError(errorMessage: String, httpCode: Int?)
		
		public var localizedDescription: String {
			if case .serverError(let message, let httpCode) = self {
				return "Server error \(httpCode ?? 0): \(message)"
			}
			return "\(self)"
		}
	}

	struct ErrorResponse: Decodable {
		let success: Bool?
		let message: String
	}

	static func parseErrorResponse(_ data: Data?, urlResponse: HTTPURLResponse?) -> Swift.Error? {
		guard let data = data,
			let errorResponse = try? client.decoder.decode(ErrorResponse.self, from: data),
			errorResponse.success != true else {
				return nil
		}
		return RequestError.serverError(errorMessage: errorResponse.message, httpCode: urlResponse?.statusCode)
	}
	
	static func request<Response: Decodable>(_ endpoint: APIEndpoint, data: Data? = nil, retries: Int = 0, completion: @escaping (Result<Response>) -> Void) {
		
		let retyingStatusCode = [429]
		let maxNumbersOfRetries = 20
		let retryDelay: TimeInterval = 0.15
		
		guard !endpoint.requiresAuthentication || client.authenticationBearer != nil else {
			// Try to authenticate once, after which the authenticationBearer *should* be set
			authorize { result in
				if case .failure(let error) = result {
					completion(.failure(error))
					return
				}
				// Just in case the authenticationBearer isn't set, make sure the authorize request doesn't happen endlessly
				if client.authenticationBearer == nil {
					completion(.failure(Error.notAuthorized))
					return
				}
				request(endpoint, data: data, completion: completion)
			}
			return
		}
		
		let urlRequest: URLRequest
		do {
			urlRequest = try client.createRequest(endpoint, data: data)
		} catch {
			completion(.failure(error))
			return
		}
		
		let task = client.urlSession.dataTask(with: urlRequest, completionHandler: { (data, urlResponse, error) in
			do {
				if let error = error {
					throw error
				}
				guard let data = data else {
					throw RequestError.invalidResponseData
				}
				let response = try client.decoder.decode(Response.self, from: data)
				completion(.success(response))
			} catch {
				let serverError = parseErrorResponse(data, urlResponse: urlResponse as? HTTPURLResponse) ?? error
				
				// Retry request after retryDelay, but only for maxNumberOfRetries
				if retries < maxNumbersOfRetries, let error = serverError as? RequestError, case .serverError(_, let statusCode) = error, let code = statusCode, retyingStatusCode.contains(code) {
					DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay, execute: {
						request(endpoint, data: data, retries: retries + 1, completion: completion)
					})
				} else {
					completion(.failure(serverError))
				}
			}
		})
		task.resume()
	}
	
	static func request<Parameters: Encodable, Response: Decodable>(_ endpoint: APIEndpoint, parameters: Parameters, completion: @escaping (Result<Response>) -> Void) {
		do {
			let encodedData = try client.encoder.encode(parameters)
			request(endpoint, data: encodedData, completion: completion)
		} catch {
			completion(.failure(error))
			return
		}
	}
}
