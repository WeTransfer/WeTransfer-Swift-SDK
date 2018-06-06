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
	
	public static func authorize(completion: @escaping (_ result: Result<Void>) -> Void) {
		if client.authenticationBearer != nil {
			completion(.success(()))
			return
		}
		
		WeTransfer.request(.authorize()) { (result: Result<AuthorizeResponse>) in
			switch result {
			case .failure(let error):
				completion(.failure(error))
			case .success(let response):
				if let token = response.token, response.success {
					client.authenticationBearer = token
					completion(.success(()))
				} else {
					completion(.failure(RequestError.authorizationFailed))
				}
			}
		}
	}
}
