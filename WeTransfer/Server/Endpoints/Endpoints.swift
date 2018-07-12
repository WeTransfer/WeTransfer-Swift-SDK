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
struct AuthorizeResponse: Decodable {
	let success: Bool
	let token: String?
}

// MARK: - Create transfer
struct CreateTransferParameters: Encodable {
	let name: String
	let description: String?
	
	init(with transfer: Transfer) {
		name = transfer.name
		description = transfer.description
	}
}

struct CreateTransferResponse: Decodable {
	let id: String // swiftlint:disable:this identifier_name
	let shortenedUrl: URL
}

// MARK: - Add files
struct AddFilesParameters: Encodable {
	struct Item: Encodable {
		let filename: String
		let filesize: UInt64
		let contentIdentifier: String
		let localIdentifier: String
		
		init(with file: File) {
			filename = file.filename
			filesize = file.filesize
			contentIdentifier = "file"
			localIdentifier = file.localIdentifier
		}
	}
	
	let items: [Item]
	
	init(with files: [File]) {
		items = files.map { file in
			return Item(with: file)
		}
	}
}

struct AddFilesResponse: Decodable {
	struct Meta: Decodable {
		let multipartParts: Int
		let multipartUploadId: String
	}
	
	let id: String
	let contentIdentifier: String
	let localIdentifier: String
	let meta: Meta
	let name: String
	let size: UInt64
	let uploadId: String
	let uploadExpiresAt: TimeInterval
}

// MARK: - Request upload URL
struct AddUploadURLResponse: Decodable {
	let uploadUrl: URL
	let partNumber: Int
	let uploadId: String
	let uploadExpiresAt: TimeInterval
}

// MARK: - Complete upload
struct CompleteUploadResponse: Decodable {
	let ok: Bool // swiftlint:disable:this identifier_name
	let message: String
}
