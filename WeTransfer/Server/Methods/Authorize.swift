//
//  Authorize.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension WeTransfer {
	
    static func compleOnMain<T>(_ completion: @escaping (_ result: Result<T>) -> Void, with result: Result<T>) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
	/// Authorizes the current user with the configured API key
	///
	/// - Parameter completion: Executes when either succeeded or failed
	/// - Parameter result: Result with empty value when succeeded, or error when failed
	static func authorize(completion: @escaping (_ result: Result<Void>) -> Void) {
		
		guard !client.authenticator.isAuthenticated else {
            compleOnMain(completion, with: .success(()))
			return
		}
		
		request(.authorize()) { result in
			switch result {
			case .failure(let error):
				guard case RequestError.serverError(_, _) = error else {
					compleOnMain(completion, with: .failure(error))
					return
				}
				compleOnMain(completion, with: .failure(WeTransfer.RequestError.authorizationFailed))
			case .success(let response):
				if let token = response.token, response.success {
					client.authenticator.updateBearer(token)
					compleOnMain(completion, with: .success(()))
				} else {
					compleOnMain(completion, with: .failure(RequestError.authorizationFailed))
				}
			}
		}
	}
}
