//
//  Authorize.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {
	
	private struct AuthorizeResponse: Decodable {
		let success: Bool
		let token: String?
	}
	
	public static func authorize(completion: @escaping (Result<String>) -> Void) throws {
		if let bearer = client.authenticationBearer {
			completion(.success(bearer))
			return
		}
		let request = try client.createRequest(.authorize(), needsToken: false)
		let task = client.urlSession.dataTask(with: request) { (data, _, error) in
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
				let serverError = parseErrorResponse(data) ?? error
				completion(.failure(serverError))
			}
		}
		task.resume()
	}
}
