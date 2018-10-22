//
//  Transfer.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Describes a single transfer to be created and uploaded. Used as an identifier between each request to be made and a local representation of the server-side transfer.
public final class Transfer: Transferable {
	public let identifier: String?

	/// The name of the transfer. This name will be shown when viewing the transfer on wetransfer.com
	public let message: String

	/// References to all the files added to the transfer
	public let files: [File]

	/// Available when the transfer is created on the server
	public private(set) var shortURL: URL?

	/// Internal initializer with required properties
	init(identifier: String, message: String, files: [File] = []) {
		self.identifier = identifier
		self.message = message
		self.files = files
	}
}

// MARK: - Private updating methods
extension Transfer {
	
	/// Updates the transfer with server-side information
	///
	/// - Parameters:
	///   - shortURL: URL of where the transfer can be found online
	func update(with shortURL: URL) {
		self.shortURL = shortURL
	}
}
