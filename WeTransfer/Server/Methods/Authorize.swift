//
//  Authorize.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {
	
	/// Authorizes the current user with the configured API key
	///
	/// - Parameter completion: Executes when either succeeded or failed
	/// - Parameter result: Result with empty value when succeeded, or error when failed
	static func authorize(completion: @escaping (_ result: Result<Void>) -> Void) {
		
		let callCompletion = { result in
			DispatchQueue.main.async {
				completion(result)
			}
		}
		
		guard !client.authenticator.isAuthenticated else {
			callCompletion(.success(()))
			return
		}
		
		request(.authorize()) { result in
			switch result {
			case .failure(let error):
				guard case RequestError.serverError(_, _) = error else {
					callCompletion(.failure(error))
					return
				}
				callCompletion(.failure(WeTransfer.RequestError.authorizationFailed))
			case .success(let response):
				if let token = response.token, response.success {
					client.authenticator.updateBearer(token)
					callCompletion(.success(()))
				} else {
					callCompletion(.failure(RequestError.authorizationFailed))
				}
			}
		}
	}
}
