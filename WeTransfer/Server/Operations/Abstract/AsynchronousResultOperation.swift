//
//  AsynchronousResultOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 29/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// An asynchronous operation which will always have a result after completion.
open class AsynchronousResultOperation<T>: AsynchronousOperation {
	
	typealias ResultHandler<T> = ((_ result: Result<T>) -> Void)

	enum Error: Swift.Error {
		case cancelled
	}
	
	private(set) var result: Result<T>? {
		didSet {
			guard let result = result else {
				return
			}
			onResult?(result)
		}
	}
	
	/// The handler to call once the result is set.
	var onResult: ResultHandler<T>?
	
	public final override func finish() {
		if isCancelled && result == nil {
			result = Result.failure(Error.cancelled)
		}
		
		assert(result != nil, "There should always be a result when finishing")
		super.finish()
	}
	
	public func finish(with result: Result<T>) {
		self.result = result
		finish()
	}
}
