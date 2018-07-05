//
//  Authenticator.swift
//  WeTransfer
//
//  Created by Pim Coumans on 28/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Responsible for adding the appropriate authentication headers to requests
final class Authenticator {
	
	var bearer: String?
	
	func authenticatedRequest(from request: URLRequest) -> URLRequest {
		var request = request
		if let bearer = bearer {
			request.addValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
		}
		return request
	}
}
