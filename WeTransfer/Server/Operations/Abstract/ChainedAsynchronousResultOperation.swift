//
//  ChainedAsynchronousResultOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

// An asynchronous operation which is dependent on a parent operation for its input.
open class ChainedAsynchronousResultOperation<Input, Output>: AsynchronousResultOperation<Output> {

	public enum Error: Swift.Error {
		case invalidInput
	}
	
	private(set) var input: Input?
	
	/// If `true`, the input value will be forwarded up on validation failure.
	/// Can be used if an operation execution is optional.
	///
	/// This requires the input type to be the same as the output type and validate(_input:) to throw no errors.
	internal var shouldForwardValueOnInvalidInput: Bool {
		return false
	}
	
	/// If `true`, this operation requires the dependency to succeed. If the dependency failed, this operation will fail directly as well.
	/// If defined `false`, the input parameter can't be nil up on execution.
	internal var requiresDependencyToSucceed: Bool {
		return true
	}
	
	/// Creates a new instance of the operation using a given input. Mainly used for making testing easier, but also used for the first operation in a chain.
	///
	/// - Parameter input: The input to use as a base. Setting this will ignore any input from dependencies.
	init(input: Input? = nil) {
		self.input = input
	}
	
	public final override func start() {
		updateInputFromDependencies()
		super.start()
	}
	
	final override public func execute() {
		do {
			if let error = dependencyResult?.error, requiresDependencyToSucceed {
				throw error
			}
			
			guard let input = input else {
				fatalError("Input should exist at this moment of execution")
			}
			
			guard try validate(input) else {
				if shouldForwardValueOnInvalidInput, let output = input as? Output {
					finish(with: Result.success(output))
					return
				}
				throw Error.invalidInput
			}
			
			execute(input)
		} catch {
			finish(with: Result.failure(error))
		}
	}
	
	open func execute(_ input: Input) {
		fatalError("Subclasses must implement `execute` without overriding super.")
	}
	
	/// Can be used by its subclasses to add any validation to the input.
	/// If the input is invalid, the `invalidInput` error will be set as the result. This can be overriden by a custom error by throwing inside this method.
	/// If a custom error is thrown, the `shouldForwardValueOnInvalidInput` value will be ignored.
	///
	/// This method will return `true` by default.
	///
	/// - Parameter input: The input to validate.
	/// - Returns: `true` if valid, otherwise `false`.
	/// - Throws: An error if validation failed. Can be used to throw a custom error as failure.
	open func validate(_ input: Input) throws -> Bool {
		return true
	}
}

extension ChainedAsynchronousResultOperation {
	
	/// Iterates over its dependencies and tries to fetch the input value.
	/// If `input` is already set, the input from dependencies will be ignored.
	private func updateInputFromDependencies() {
		guard input == nil else {
			return
		}
		input = dependencyResult?.value
	}
	
	/// Iterates over its dependencies and tries to fetch the result value.
	/// Will always get the first result matching dependency.
	private var dependencyResult: Result<Input>? {
		return dependencies.compactMap { dependency in
			return dependency as? AsynchronousResultOperation<Input>
		}.first?.result
	}
}

extension Array where Element == Operation {
	func chained() -> [Element] {
		for item in enumerated() where item.offset > 0 {
			item.element.addDependency(self[item.offset - 1])
		}
		return self
	}
}
