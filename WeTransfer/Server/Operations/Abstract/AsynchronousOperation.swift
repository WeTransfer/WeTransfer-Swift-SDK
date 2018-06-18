//
//  AsynchronousOperation.swift
//  WeTransfer
//
//  Created by Pim Coumans on 29/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// A base class to handle NSOperation states, because this is quite verbose due to KVO and the combined attribute states.
open class AsynchronousOperation: Operation {
	
	// MARK: - Types
	
	/// An option set to express all the possible Operation states.
	private struct State: OptionSet {
		let rawValue: Int
		static let executing = State(rawValue: 1 << 0)
		static let finished = State(rawValue: 1 << 1)
		static let cancelled = State(rawValue: 1 << 2)
		
		var executing: Bool {
			get {
				return contains(.executing)
			}
			set {
				if newValue {
					insert(.executing)
				} else {
					remove(.executing)
				}
			}
		}
		
		var finished: Bool {
			get {
				return contains(.finished)
			}
			set {
				if newValue {
					insert(.finished)
				} else {
					remove(.finished)
				}
			}
		}
		
		var cancelled: Bool {
			get {
				return contains(.cancelled)
			}
			set {
				if newValue {
					insert(.cancelled)
				} else {
					remove(.cancelled)
				}
			}
		}
	}
	
	// MARK: - State
	
	/// The dispatch queue that's used for mutating and reading the operation state. The state should be able to be read by multiple threads at once, but should obviously only be mutated by 1 thread at a time.
	private let stateQueue = DispatchQueue(label: "com.wetransfer.swiftsdk.dataoperation.state", attributes: [.concurrent])
	
	/// A private option set to define the operation state. Should only be mutated by the dedicated setters in AsynchronousOperation, to guarantee thread-safety.
	private var rawState = State()
	
	/// A thread safe overridden isExecuting property from NSOperation. Returns whether the operation is currently executing its tasks. This is fully managed by the AsynchronousOperation class.
	private(set) public final override var isExecuting: Bool {
		get {
			return stateQueue.sync {
				return rawState.executing
			}
		}
		set {
			willChangeValue(forKey: "isExecuting")
			stateQueue.sync(flags: [.barrier]) {
				rawState.executing = newValue
			}
			didChangeValue(forKey: "isExecuting")
		}
	}
	
	/// A thread safe overridden isFinished property from NSOperation. Returns whether the operation is done with its task. This is fully managed by the AsynchronousOperation class.
	private(set) public final override var isFinished: Bool {
		get {
			return stateQueue.sync {
				return rawState.finished
			}
		}
		set {
			willChangeValue(forKey: "isFinished")
			stateQueue.sync(flags: [.barrier]) {
				rawState.finished = newValue
			}
			didChangeValue(forKey: "isFinished")
		}
	}
	
	/// A thread safe overridden isCancelled property from NSOperation. Returns whether the operation has been cancelled. This is fully managed by the AsynchronousOperation class.
	private(set) public final override var isCancelled: Bool {
		get {
			return stateQueue.sync {
				return rawState.cancelled
			}
		}
		set {
			willChangeValue(forKey: "isCancelled")
			stateQueue.sync(flags: [.barrier]) {
				rawState.cancelled = newValue
			}
			didChangeValue(forKey: "isCancelled")
		}
	}
	
	// MARK: - Operation
	
	/// Overridden method from NSOperation.
	public final override var isAsynchronous: Bool {
		return true
	}
	
	/// Overridden method from NSOperation. Starts executing the operation work. This is final, because subclasses should use the execute() method instead.
	open override func start() {
		super.start()
		
		guard !isCancelled else {
			finish()
			return
		}
		
		isFinished = false
		isExecuting = true
		execute()
	}
	
	/// Subclasses must implement this to perform their work and they must not call `super`. The default implementation of this function throws an exception.
	open func execute() {
		fatalError("Subclasses must implement `execute` without overriding super.")
	}
	
	/// Call this function after any work is done to move the operation into a completed state.
	open func finish() {
		isExecuting = false
		isFinished = true
	}
	
	/// Overridden cancel method from NSOperation. Cancels the current execution, if possible.
	open override func cancel() {
		super.cancel()
		isCancelled = true
		
		// Only finish if we're already executing. Otherwise we'll end up in a finished state while the operation has not even started. This will cause an exception and crashes the app.
		if isExecuting {
			isExecuting = false
			isFinished = true
		}
	}
}
