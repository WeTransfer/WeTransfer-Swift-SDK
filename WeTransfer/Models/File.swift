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

/// A file used in a Transfer object. Should be initialized with a URL pointing only to a local file
/// As files should be readily available for uploading, only local files accessible by NSFileManager should be used for transfers
public final class File: Encodable {
	
	public enum Error: Swift.Error, LocalizedError {
		/// Provided file URL could not be used to get file size information
		case fileSizeUnavailable
		
		public var errorDescription: String? {
			switch self {
			case .fileSizeUnavailable:
				return "No file size information available"
			}
		}
	}
	
	/// Location of the file on disk
	public let url: URL
	
	/// Server-side identifier when file is added to the transfer on the server
	public private(set) var identifier: String?
	
	/// Will be set to yes when all chunks of the file have been uploaded
	public internal(set) var isUploaded: Bool = false

	/// Name of the file. Should be the last path component of the url
	public var filename: String {
		return url.lastPathComponent
	}
	
	/// Size of the file in Bytes
	public let filesize: Bytes
	
	/// Unique identifier to keep track of files locally
	let localIdentifier = UUID().uuidString

	public private(set) var numberOfChunks: Int?
	private(set) var multipartUploadIdentifier: String?

	public init(url: URL) throws {
		self.url = url
		
		let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
		guard let filesizeAttribute = fileAttributes[.size] as? UInt64 else {
			throw Error.fileSizeUnavailable
		}
		self.filesize = filesizeAttribute
	}
}

extension File: Equatable {
	/// Only compares the url and localIdentifier of the File
	/// Note: Disregards any state, so the `uploaded` property is ignored
	public static func == (lhs: File, rhs: File) -> Bool {
		return lhs.url == rhs.url && lhs.localIdentifier == rhs.localIdentifier
	}
}

extension File {
	func update(with identifier: String, numberOfChunks: Int, multipartUploadIdentifier: String) {
		self.identifier = identifier
		self.numberOfChunks = numberOfChunks
		self.multipartUploadIdentifier = multipartUploadIdentifier
	}
}
