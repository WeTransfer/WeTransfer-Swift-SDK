//
//  AsynchronousResultOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 29/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// An asynchronous operation which will always have a result after completion.
open class AsynchronousDependencyResultOperation<T>: AsynchronousResultOperation<T> {
	
	open override func execute() {
		let resultDependencies = dependencies.compactMap({ $0 as? AsynchronousResultOperation<T> })
		
		let errors = resultDependencies.compactMap({ $0.result?.error })
		let results = resultDependencies.compactMap({ $0.result?.value })
		
		// For now, both the last error or the last result are used from all dependencies.
		// While this is not ideal, in the use case of this project only the last error or result is actually needed
		if let error = errors.last {
			finish(with: .failure(error))
		} else if let result = results.last {
			finish(with: .success(result))
		} else {
			finish()
		}
	}
}
