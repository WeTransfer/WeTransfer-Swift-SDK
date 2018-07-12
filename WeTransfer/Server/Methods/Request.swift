//
//  Request.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {

	/// General errors that can be returned from all requests
	public enum RequestError: Swift.Error, LocalizedError {
		/// Response returned from server could not be parsed
		case invalidResponseData
		/// Provided API key is not valid
		case authorizationFailed
		/// Error returned by server
		/// - errorMessage: Description of error
		/// - httpCode: The http status code of server response, if available
		case serverError(errorMessage: String, httpCode: Int?)
		
		public var errorDescription: String? {
			switch self {
			case .invalidResponseData:
				return "Invalid response data: Server returned unrecognized response"
			case .authorizationFailed:
				return "Authorization failed: Invalid API key used for request"
			case .serverError(let message, let httpCode):
				return "Server error \(httpCode ?? 0): \(message)"
			}
		}
	}

	/// Response returned by server when request could not be completed
	struct ErrorResponse: Decodable {
		/// Whether the request has succeeded (typically `false`)
		let success: Bool?
		/// Message describing the error returned from the API
		let message: String?
		/// Actual error message from the server
		let error: String?
		
		/// String using either the message or the error property
		var errorString: String {
			return (message ?? error) ?? ""
		}
	}

	/// Tries to create an error from the server response if decoding of expected response failed
	///
	/// - Parameters:
	///   - data: Data of the response
	///   - urlResponse: Response description, from which a status code can be read
	/// - Returns: An error if type RequestError.serverEror if error response could be parsed
	static func parseErrorResponse(_ data: Data?, urlResponse: HTTPURLResponse?) -> Swift.Error? {
		guard let data = data,
			let errorResponse = try? client.decoder.decode(ErrorResponse.self, from: data),
			errorResponse.success != true else {
				return nil
		}
		return RequestError.serverError(errorMessage: errorResponse.errorString, httpCode: urlResponse?.statusCode)
	}
	
	/// Creates and performs a request to the given endpoint with the provided encodable Parameters. The response of the request will be decoded to Response type, set by declaring the result in the completion closure
	///
	/// - Parameters:
	///   - endpoint: The Endpoint containing the url and HTTP method for the request
	///   - parameters: Decodable parameters to send along with the request
	///   - completion: Closure called when either request has failed, or succeeded with the decoded Response type
	///   - result: Result with either the decoded Response or and error describing where the request went wrong
	static func request<Parameters: Encodable, Response>(_ endpoint: APIEndpoint<Response>, parameters: Parameters, completion: @escaping (_ result: Result<Response>) -> Void) {
		do {
			let encodedData = try client.encoder.encode(parameters)
			request(endpoint, data: encodedData, completion: completion)
		} catch {
			completion(.failure(error))
			return
		}
	}
	
	/// Creates and performs a request to the given endpoint with the optionally provided data. The response of the request will be decoded to Response type, set by declaring the result in the completion closure
	///
	/// - Parameters:
	///   - endpoint: The Endpoint containing the url and HTTP method for the request
	///   - data: The encoded data to be sent as parameters along with the request
	///   - completion: Closure called when either request has failed, or succeeded with the decoded Response type
	///   - result: Result with either the decoded Response or and error describing where the request went wrong
	static func request<Response>(_ endpoint: APIEndpoint<Response>, data: Data? = nil, completion: @escaping (_ result: Result<Response>) -> Void) {
		
		guard !endpoint.requiresAuthentication || client.authenticator.isAuthenticated else {
			// Try to authenticate once, after which the authenticationBearer *should* be set
			authorize { result in
				if case .failure(let error) = result {
					completion(.failure(error))
					return
				}
				// Just in case the authenticationBearer isn't set, make sure the authorize request doesn't happen endlessly
				if !client.authenticator.isAuthenticated {
					completion(.failure(Error.notAuthorized))
					return
				}
				request(endpoint, data: data, completion: completion)
			}
			return
		}
		
		// Create the request with the enpoint and optional data
		let urlRequest: URLRequest
		do {
			urlRequest = try client.createRequest(endpoint, data: data)
		} catch {
			completion(.failure(error))
			return
		}
		
		// Create and start a dataTask, after which the reponse is decoded to the Response type
		let task = client.urlSession.dataTask(with: urlRequest, completionHandler: { (data, urlResponse, error) in
			do {
				if let error = error {
					throw error
				}
				guard let data = data else {
					throw RequestError.invalidResponseData
				}
				let response = try client.decoder.decode(endpoint.responseType, from: data)
				completion(.success(response))
			} catch {
				let serverError = parseErrorResponse(data, urlResponse: urlResponse as? HTTPURLResponse) ?? error
				completion(.failure(serverError))
			}
		})
		task.resume()
	}
}
