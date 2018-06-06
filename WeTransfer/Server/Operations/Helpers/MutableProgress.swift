//
//  MutableProgress.swift
//  WeTransfer
//
//  Created by Pim Coumans on 04/06/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// An additional class build on top of `Progress` to make it possible to also remove children from progress.
public final class MutableProgress: Progress {
	
	public override var totalUnitCount: Int64 {
		get {
			return dispatchQueue.sync {
				return Int64(children.count)
			}
		}
		set {
			fatalError("Setting the total unit count is not supported for MutableProgress")
		}
	}
	
	public override var completedUnitCount: Int64 {
		get {
			return dispatchQueue.sync {
				return Int64(children.filter { $0.key.isCompleted }.count)
			}
		}
		set {
			fatalError("Setting the completed unit count is not supported for MutableProgress")
		}
	}
	
	public override var fractionCompleted: Double {
		return dispatchQueue.sync {
			return children.map { $0.key.fractionCompleted }.reduce(0, +) / Double(children.count)
		}
	}
	
	/// All the current tracked children.
	private(set) var children: [Progress: NSKeyValueObservation] = [:]
	
	/// The queue which is used to make sure the mutable progress is only modified serially.
	private let dispatchQueue = DispatchQueue(label: "com.rabbit.MutableProgress.DispatchQueue")
	
	deinit {
		children.values.forEach { $0.invalidate() }
		children.removeAll()
	}
	
	/// Adds a new child. Will always use a pending unit count of 1.
	///
	/// - Parameter child: The child to add.
	func addChild(_ child: Progress) {
		willChangeValue(for: \.totalUnitCount)
		dispatchQueue.sync {
			self.children[child] = child.observe(\.fractionCompleted) { [weak self] (progress, _) in
				self?.willChangeValue(for: \.fractionCompleted)
				self?.didChangeValue(for: \.fractionCompleted)
				
				if progress.isCompleted {
					self?.willChangeValue(for: \.completedUnitCount)
					self?.didChangeValue(for: \.completedUnitCount)
				}
			}
		}
		didChangeValue(for: \.totalUnitCount)
	}
	
	/// Removes the given child from the progress reporting.
	///
	/// - Parameter child: The child to remove.
	func removeChild(_ child: Progress) {
		willChangeValue(for: \.fractionCompleted)
		willChangeValue(for: \.completedUnitCount)
		willChangeValue(for: \.totalUnitCount)
		
		dispatchQueue.sync {
			self.children[child]?.invalidate()
			self.children.removeValue(forKey: child)
		}
		
		didChangeValue(for: \.totalUnitCount)
		didChangeValue(for: \.completedUnitCount)
		didChangeValue(for: \.fractionCompleted)
	}
	
	// MARK: Overriding methods to make sure this class is used correctly.
	public override func addChild(_ child: Progress, withPendingUnitCount inUnitCount: Int64) {
		assert(inUnitCount == 1, "Unit count is ignored and is fixed to 1 for MutableProgress")
		addChild(child)
	}
}

public extension Progress {
	
	/// Returns wether the current progress is completed or not.
	/// The fractionCompleted property is useful for updating progress indicators or textual descriptors; to check whether progress is complete, you should test that completedUnitCount >= totalUnitCount (assuming, of course, that totalUnitCount > 0).
	public var isCompleted: Bool {
		guard totalUnitCount > 0 else { return true }
		return completedUnitCount >= totalUnitCount
	}
	
	/// Adds the process objects as a child of the progress tree.
	/// The childs will be assigned a portion of the receivers total unit count based on a pending unit count of 1.
	func addChildren(_ children: [Progress]) {
		children.forEach { progress in
			addChild(progress, withPendingUnitCount: 1)
		}
	}
}
