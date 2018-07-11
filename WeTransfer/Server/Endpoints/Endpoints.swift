//
//  Endpoints.swift
//  WeTransfer
//
//  Created by Pim Coumans on 01/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

// MARK: - Authorize
struct AuthorizeResponse: Decodable {
	let success: Bool
	let token: String?
}

extension APIEndpoint {
	static func authorize() -> APIEndpoint<AuthorizeResponse> {
		// Only request that doesn't require a jwt token to be set
		return APIEndpoint<AuthorizeResponse>(method: .post, path: "authorize", requiresAuthentication: false)
	}
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

extension APIEndpoint {
	static func createTransfer() -> APIEndpoint<CreateTransferResponse> {
		return APIEndpoint<CreateTransferResponse>(method: .post, path: "transfers")
	}
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

extension APIEndpoint {
	static func addItems(transferIdentifier: String) -> APIEndpoint<[AddFilesResponse]> {
		return APIEndpoint<[AddFilesResponse]>(method: .post, path: "transfers/\(transferIdentifier)/items")
	}
}

// MARK: - Request upload URL
struct AddUploadURLResponse: Decodable {
	let uploadUrl: URL
	let partNumber: Int
	let uploadId: String
	let uploadExpiresAt: TimeInterval
}

extension APIEndpoint {
	static func requestUploadURL(fileIdentifier: String, chunkIndex: Int, multipartIdentifier: String) -> APIEndpoint<AddUploadURLResponse> {
		let partNumber = chunkIndex + 1
		return APIEndpoint<AddUploadURLResponse>(method: .get, path: "files/\(fileIdentifier)/uploads/\(partNumber)/\(multipartIdentifier)")
	}
}

// MARK: - Complete upload
struct CompleteUploadResponse: Decodable {
	let ok: Bool // swiftlint:disable:this identifier_name
	let message: String
}

extension APIEndpoint {
	static func completeUpload(fileIdentifier: String) -> APIEndpoint<CompleteUploadResponse> {
		return APIEndpoint<CompleteUploadResponse>(method: .post, path: "files/\(fileIdentifier)/uploads/complete")
	}
}
