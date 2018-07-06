//
//  Transfer.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

/// Desribes a single transfer to be created, updated and sent. Used as an identifier between each request to be made and a local representation of the server-side transfer.
/// Can be initialized with files or these can be added later through the add files function
final public class Transfer {
	public private(set) var identifier: String?

	/// The name of the transfer. This name will be shown when viewing the transfer on wetransfer.com
	public let name: String
	/// Optional description of the transfer. This will be shown when viewing the transfer on wetransfer.com
	public let description: String?

	/// References to all the files added to the transfer. Add other files with the public method on the WeTransfer struct or add them directly when initializing the transfer object
	public private(set) var files: [File] = []

	/// Available when the transfer is created on the server
	public private(set) var shortURL: URL?

	public init(name: String, description: String?, files: [File] = []) {
		self.name = name
		self.description = description
		self.files = files
	}
}

// MARK: - Private updating methods
extension Transfer {
	
	func update(with identifier: String, shortURL: URL) {
		self.identifier = identifier
		self.shortURL = shortURL
	}

	func add(_ files: [File]) {
		for file in files where !self.files.contains(file) {
			self.files.append(file)
		}
	}

	func updateFiles(_ updater: (File) -> File) {
		files = files.map { file in
			return updater(file)
		}
	}

	func setFileUploaded(_ file: File) {
		guard let index = files.index(of: file) else {
			return
		}
		files[index].isUploaded = true
	}
}
