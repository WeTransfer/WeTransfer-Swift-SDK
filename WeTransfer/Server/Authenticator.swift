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
	
	/// JWT bearer to add to request
	private var bearer: String?
	
	/// Whether a bearer is set and thus the client is authenticated
	var isAuthenticated: Bool {
		return bearer != nil
	}
	
	/// Updates the JWT bearer with a new bearer
	///
	/// - Parameter bearer: New bearer
	func updateBearer(_ bearer: String?) {
		self.bearer = bearer
	}
	
	/// Authenticates the provided request with the correct authorization headers if a bearer is set
	/// - Note: Can be called regardless of availability of JWT bearer
	///
	/// - Parameter request: The request to update
	/// - Returns: An updated request with the correct authorization headers added
	func authenticatedRequest(from request: URLRequest) -> URLRequest {
		var request = request
		if let bearer = bearer {
			request.addValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
		}
		return request
	}
}
