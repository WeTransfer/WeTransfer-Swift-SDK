//
//  File.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Amount of bytes in a file or chunk
public typealias Bytes = UInt64

/// A file used in a Transfer object. Should be initialized with a URL pointing to a local file
public struct File: Encodable {
	
	public enum Error: Swift.Error {
		case fileSizeUnavailable
	}
	
	/// Location of the file on disk
	public let url: URL
	
	/// Server-side identifier when file is added to the transfer on the server
	public private(set) var identifier: String?
	
	/// Will be set to yes when all chunks of the file have been uploaded
	public internal(set) var uploaded: Bool = false

	/// Name of the file. Should be the last path component of the url
	public let filename: String
	
	/// Size of the file in Bytes
	public let filesize: Bytes
	
	/// Unique identifier to keep track of files locally
	let localIdentifier = UUID().uuidString

	public private(set) var numberOfChunks: Int?
	private(set) var multipartUploadIdentifier: String?

	public init(url: URL) throws {
		self.url = url
		filename = url.lastPathComponent
		
		let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
		guard let filesizeAttribute = fileAttributes[.size] as? UInt64 else {
			throw Error.fileSizeUnavailable
		}
		self.filesize = filesizeAttribute
	}
}

extension File: Equatable {
	public static func == (lhs: File, rhs: File) -> Bool {
		return lhs.url == rhs.url && lhs.localIdentifier == rhs.localIdentifier
	}
}

extension File {
	func updated(with response: AddFilesResponse) -> File {
		var file = self
		file.identifier = response.id
		file.numberOfChunks = response.meta.multipartParts
		file.multipartUploadIdentifier = response.meta.multipartUploadId
		return file
	}
}
