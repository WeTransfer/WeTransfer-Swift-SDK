//
//  Result.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Enum with either a value when succeeded or an error when failed
public enum Result<Value> {
	/// The operation has succeeded and requested value is available
	case success(Value)
	/// The operation has failed with the provided error
	case failure(Error)

	public var error: Error? {
		guard case .failure(let error) = self else { return nil }
		return error
	}

	public var value: Value? {
		guard case .success(let value) = self else { return nil }
		return value
	}
}
