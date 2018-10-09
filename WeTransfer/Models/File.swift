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

/// A file used in a Transfer or a Board. Should be initialized with a URL pointing only to a local file
/// As files should be readily available for uploading, only local files accessible by NSFileManager should be used
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
	
	/// Server-side identifier when file is added to the transfer or board on the server
	public private(set) var identifier: String?
	
	/// Will be set to yes when all chunks of the file have been uploaded
	public internal(set) var isUploaded: Bool = false

	/// Name of the file. Should be the last path component of the url
	public var filename: String {
		return url.lastPathComponent
	}
	
	/// Size of the file in Bytes
	public let filesize: Bytes
	
	/// Maximum size that each chunk needs to be
	public internal(set) var chunkSize: Bytes?

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
	/// Only compares the url and optional identifier of the file
	/// Note: Disregards any state, so the `uploaded` property is ignored
	public static func == (lhs: File, rhs: File) -> Bool {
		return lhs.url == rhs.url && lhs.identifier == rhs.identifier
	}
}

extension File {
	func update(with identifier: String, numberOfChunks: Int, chunkSize: Bytes, multipartUploadIdentifier: String?) {
		self.identifier = identifier
		self.numberOfChunks = numberOfChunks
		self.chunkSize = chunkSize
		self.multipartUploadIdentifier = multipartUploadIdentifier
	}
}
