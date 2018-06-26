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
/// Can be initialized with files or these can be added later via `WeTransfer.addFiles(files: to transfer:)`
final public class Transfer: Encodable {
	public private(set) var identifier: String?

	public let name: String
	public let description: String?

	public private(set) var files: [File] = []

	public private(set) var shortURL: URL?

	public init(name: String, description: String?, files: [File] = []) {
		self.name = name
		self.description = description
		self.files = files
	}
}

// MARK: - Private updating methods
extension Transfer {
	func update(with response: CreateTransferResponse) {
		identifier = "\(response.id)"
		shortURL = response.shortenedUrl
	}

	func add(files: [File]) {
		for file in files where !self.files.contains(file) {
			self.files.append(file)
		}
	}

	func updateFiles(with responseFiles: [AddFilesResponse]) {
		files = files.map { file in
			guard let responseFile = responseFiles.first(where: { $0.localIdentifier == file.localIdentifier }) else {
				return file
			}
			return file.updated(with: responseFile)
		}
	}

	func setFileUploaded(_ file: File) {
		guard let index = files.index(of: file) else {
			return
		}
		files[index].isUploaded = true
	}
}
