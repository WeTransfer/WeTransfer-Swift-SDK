//
//  Endpoints.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

extension APIEndpoint {
	/// Sends the API key to authorize the client to use the API
	///
	/// - Returns: APIEndpoint with `POST` to `/authorize` without a token in the headers, expecting a `AuthorizerResponse` as response
	static func authorize() -> APIEndpoint<AuthorizeResponse> {
		return APIEndpoint<AuthorizeResponse>(method: .post, path: "authorize", requiresAuthentication: false)
	}
	
	/// Creates a new transfer
	///
	/// - Returns: APIEndpoint with `POST` to `/transfer`, expecting a `CreateTransferResponse` as response
	static func createTransfer() -> APIEndpoint<CreateTransferResponse> {
		return APIEndpoint<CreateTransferResponse>(method: .post, path: "transfers")
	}
	
	/// Adds files to an existing transfer
	///
	/// - Parameter transferIdentifier: Identifier of the transfer to add the files to
	/// - Returns: APIEndpoint with `POST` to `/transfers/{id}/items`, expecting an array of `AddFilesResponse` structs as response
	static func addItems(transferIdentifier: String) -> APIEndpoint<[AddFilesResponse]> {
		return APIEndpoint<[AddFilesResponse]>(method: .post, path: "transfers/\(transferIdentifier)/items")
	}
	
	/// Requests upload info of a chunk of a file to be uploaded
	///
	/// - Parameters:
	///   - fileIdentifier: Identifier of the file to get the chunk info of
	///   - chunkIndex: Index of the chunk
	///   - multipartIdentifier: Multipart identifier of the file
	/// - Returns: APIEndpoint with `GET` to `/files/{file-id}/uploads/{chunk-number}/{multipart-id}`
	static func requestUploadURL(fileIdentifier: String, chunkIndex: Int, multipartIdentifier: String) -> APIEndpoint<AddUploadURLResponse> {
		let partNumber = chunkIndex + 1
		return APIEndpoint<AddUploadURLResponse>(method: .get, path: "files/\(fileIdentifier)/uploads/\(partNumber)/\(multipartIdentifier)")
	}
	
	/// Completes the upload of file, assuming all chunks have finished uploading
	///
	/// - Parameter fileIdentifier: Identifier of the file
	/// - Returns: APIEndpoint with `POST` to `/files/{file-id}/uploads/complete`
	static func completeUpload(fileIdentifier: String) -> APIEndpoint<CompleteUploadResponse> {
		return APIEndpoint<CompleteUploadResponse>(method: .post, path: "files/\(fileIdentifier)/uploads/complete")
	}
}

// MARK: - Authorize

/// Response from authenticate request
struct AuthorizeResponse: Decodable {
	/// Whether authorization has succeeded
	let success: Bool
	/// The JWT to use in future requests
	let token: String?
}

// MARK: - Create transfer

/// Parameters used for the create transfer request
struct CreateTransferParameters: Encodable {
	/// Name of the transfer to create
	let name: String
	/// Description of the transfer to create
	let description: String?
	
	/// Initializes the parameters with a local transfer object
	///
	/// - Parameter transfer: Transfer object to create on the server
	init(with transfer: Transfer) {
		name = transfer.name
		description = transfer.description
	}
}

/// Response from create transfer request
struct CreateTransferResponse: Decodable {
	/// Server side identifier of the transfer
	let id: String // swiftlint:disable:this identifier_name
	/// The URL to where the transfer can be found online
	let shortenedUrl: URL
}

// MARK: - Add files

/// Parameters used for the add files request
struct AddFilesParameters: Encodable {
	/// Describes a file to be added to the transfer
	struct Item: Encodable {
		/// Full name of file (e.g. "photo.jpg")
		let filename: String
		/// Filesize in bytes
		let filesize: UInt64
		/// Type of content, currently always "file"
		let contentIdentifier: String = "file"
		/// Identifier to uniquely identify file locally
		let localIdentifier: String
		
		/// Initializes Item struct with a File struct
		///
		/// - Parameter file: File struct to initialize Item from
		init(with file: File) {
			filename = file.filename
			filesize = file.filesize
			localIdentifier = file.localIdentifier
		}
	}
	
	/// All items to be added to the transfer
	let items: [Item]
	
	/// Initalizes the parameters with an array of File structs
	///
	/// - Parameter files: Array of File structs to be added to the transfer
	init(with files: [File]) {
		items = files.map { file in
			return Item(with: file)
		}
	}
}

/// Response from the add files request
struct AddFilesResponse: Decodable {
	/// Contains information about the chunks and the upload identifier
	struct Meta: Decodable {
		let multipartParts: Int
		let multipartUploadId: String
	}
	
	/// Identifier of the File on the server
	let id: String
	/// Local identifier of the file to identify the local file with
	let localIdentifier: String
	/// Number of multiparts (chunks) and upload identifier for uploading
	let meta: Meta
}

// MARK: - Request upload URL

/// Response from the add upload url request for chunks
struct AddUploadURLResponse: Decodable {
	/// URL to upload the chunk to
	let uploadUrl: URL
	/// Number of the chunk
	let partNumber: Int
	/// Time interval when the upload URL is no longer valid and upload URL should be requested again
	let uploadExpiresAt: TimeInterval
}

// MARK: - Complete upload

/// Response from complete upload request
struct CompleteUploadResponse: Decodable {
	/// Whether the upload of all the chunks has succeeded
	let ok: Bool // swiftlint:disable:this identifier_name
	/// Message describing either success or failure of chunk uploads
	let message: String
}
