//
//  Transfer.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 01/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Describes a single board to be created, adding files to and uploading files from. Used as an identifier between each request to be made and a local representation of the server-side board.
/// Files should be added through the appropriate addFiles method
public final class Board: Transferable {
	public private(set) var identifier: String?

	/// The name of the board. This name will be shown when viewing the transfer on wetransfer.com
	public let name: String
	/// Optional description of the board. This will be shown when viewing the transfer on wetransfer.com
	public let description: String?

	/// References to all the files added to the board. Files can be added with the public method on the WeTransfer struct
	public private(set) var files: [File] = []

	/// Available when the board is created on the server
	public private(set) var shortURL: URL?
	
	/// Internal initializer with required properties
	init(name: String, description: String?) {
		self.name = name
		self.description = description
	}
}

// MARK: - Private updating methods
extension Board {
	
	/// Updates the board with server-side information
	///
	/// - Parameters:
	///   - identifier: Identifier to point to global board
	///   - shortURL: URL of where the board can be found online
	func update(with identifier: String, shortURL: URL) {
		self.identifier = identifier
		self.shortURL = shortURL
	}

	/// Adds provided files to the board locally
	///
	/// - Parameter files: Files to be added to the board
	func add(_ files: [File]) {
		for file in files where !self.files.contains(file) {
			self.files.append(file)
		}
	}
}
