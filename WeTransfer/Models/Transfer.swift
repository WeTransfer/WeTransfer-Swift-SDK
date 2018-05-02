//
//  Transfer.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

public class Transfer: Identifiable, Encodable {
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

extension Transfer {
	internal func update(with response: WeTransfer.CreateTransferResponse) {
		identifier = "\(response.id)"
		shortURL = response.shortenedUrl
	}
	
	internal func addFiles(_ files: [File]) {
		self.files.append(contentsOf: files)
	}
	
	internal func updateFiles(with responseFiles: [WeTransfer.AddFilesResponse]) {
		files = files.map { file in
			guard let responseFile = responseFiles.first(where: { $0.localIdentifier == file.localIdentifier }) else {
				return file
			}
			return file.updated(with: responseFile)
		}
	}
	
	internal func updateFile(_ file: File, with chunkResponse: WeTransfer.AddUploadURLResponse) {
		guard let fileIndex = files.index(where: { $0.localIdentifier == file.localIdentifier }) else {
			return
		}
		files[fileIndex] = file.updated(with: chunkResponse)
	}
}
