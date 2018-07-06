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
	
	private(set) var bearer: String?
	
	var isAuthenticated: Bool {
		return bearer != nil
	}
	
	func updateBearer(_ bearer: String?) {
		self.bearer = bearer
	}
	
	func authenticatedRequest(from request: URLRequest) -> URLRequest {
		var request = request
		if let bearer = bearer {
			request.addValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
		}
		return request
	}
}
