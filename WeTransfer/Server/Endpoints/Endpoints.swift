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
	
	/// Creates a new transfer
	///
	/// - Returns: APIEndpoint with `POST` to `/transfer`, expecting a `CreateTransferResponse` as response
	static func createBoard() -> APIEndpoint<CreateBoardResponse> {
		return APIEndpoint<CreateBoardResponse>(method: .post, path: "boards")
	}
	
	/// Adds files to an existing board
	///
	/// - Parameter boardIdentifier: Identifier of the board to add the files to
	/// - Returns: APIEndpoint with `POST` to `/boards/{id}/items`, expecting an array of `AddFilesResponse` structs as response
	static func addFiles(boardIdentifier: String) -> APIEndpoint<[AddFilesResponse]> {
		return APIEndpoint<[AddFilesResponse]>(method: .post, path: "boards/\(boardIdentifier)/files")
	}
	
	/// Requests upload info of a chunk of a file to be uploaded
	///
	/// - Parameters:
	///   - transferIdentifier: Identifier of the transfer containing the file
	///   - fileIdentifier: Identifier of the file to get the chunk info of
	///   - chunkIndex: Index of the chunk
	/// - Returns: APIEndpoint with `GET` to `/transfers/files/{file-id}/upload-url/{part-number}/
	static func requestTransferUploadURL(transferIdentifier: String, fileIdentifier: String, chunkIndex: Int) -> APIEndpoint<AddUploadURLResponse> {
		let partNumber = chunkIndex + 1
		return APIEndpoint<AddUploadURLResponse>(method: .get, path: "transfers/\(transferIdentifier)/files/\(fileIdentifier)/upload-url/\(partNumber)")
	}
	
	/// Requests upload info of a chunk of a file to be uploaded
	///
	/// - Parameters:
	///   - boardIndentifier: dentifier of the board containing the file
	///   - fileIdentifier: Identifier of the file to get the chunk info of
	///   - chunkIndex: Index of the chunk
	///   - multipartIdentifier: Multipart identifier of the file
	/// - Returns: APIEndpoint with `GET` to `/files/{file-id}/uploads/{chunk-number}/{multipart-id}`
	static func requestBoardUploadURL(boardIdentifier: String, fileIdentifier: String, chunkIndex: Int, multipartIdentifier: String) -> APIEndpoint<AddUploadURLResponse> {
		let partNumber = chunkIndex + 1
		return APIEndpoint<AddUploadURLResponse>(method: .get, path: "boards/\(boardIdentifier)/files/\(fileIdentifier)/upload-url/\(partNumber)/\(multipartIdentifier)")
	}
	
	/// Completes the upload of file, assuming all chunks have finished uploading
	///
	/// - Parameters:
	///   - transferIdentifier: Identifier for the containing transfer
	///   - fileIdentifier: Identifier of the file
	/// - Returns: APIEndpoint with `POST` to `/files/{file-id}/uploads/complete`
	static func completeTransferFileUpload(transferIdentifier: String, fileIdentifier: String) -> APIEndpoint<EmptyResponse> {
		return APIEndpoint<EmptyResponse>(method: .put, path: "transfers/\(transferIdentifier)/files/\(fileIdentifier)/upload-complete")
	}
	
	/// Completes the upload of file, assuming all chunks have finished uploading
	///
	/// - Parameters:
	///   - boardIdentifier: Identifier for the containing board
	///   - fileIdentifier: Identifier of the file
	/// - Returns: APIEndpoint with `POST` to `/files/{file-id}/uploads/complete`
	static func completeBoardFileUpload(boardIdentifier: String, fileIdentifier: String) -> APIEndpoint<CompleteBoardFileUploadResponse> {
		return APIEndpoint<CompleteBoardFileUploadResponse>(method: .put, path: "boards/\(boardIdentifier)/files/\(fileIdentifier)/upload-complete")
	}
	
	/// Finilizes the transfer, resulting in an URL to be added to the transfer
	///
	/// - Parameter transferIdentifier: Identifier for the transfer
	/// - Returns: APIEndopint with `PUT` to `transfers/{transfer-id}/finalize`
	static func finalizeTransfer(transferIdentifier: String) -> APIEndpoint<FinalizeTransferResponse> {
		return APIEndpoint<FinalizeTransferResponse>(method: .put, path: "transfers/\(transferIdentifier)/finalize")
	}
}

// MARK: - Request parameters and responses

/// Generic empty response when no response data is expected or needed
struct EmptyResponse: Decodable {
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
	
	struct FileParameters: Encodable {
		let name: String
		let size: UInt64
	}
	
	/// Message to go with the transfer
	let message: String
	/// Description of all the files to add
	let files: [FileParameters]
	
	/// Initializes the parameters with a local transfer object
	///
	/// - Parameter transfer: Transfer object to create on the server
	init(message: String, files: [File]) {
		self.message = message
		
		self.files = files.map({ file in
			return FileParameters(name: file.filename, size: file.filesize)
		})
	}
}

/// Response from create transfer request
struct CreateTransferResponse: Decodable {
	struct FileResponse: Decodable {
		// swiftlint:disable nesting
		/// Multipart upload information about each chunk
		struct MultipartUploadInfo: Decodable {
			/// Amount of chunks to be created
			let partNumbers: Int
			/// Default size for each chunk
			let chunkSize: Bytes
		}
		
		let identifier: String
		/// Full name of file (e.g. "photo.jpg")
		let name: String
		// Size of the file in bytes
		let size: Bytes
		/// Mulitpart information about each chunk
		let multipartUploadInfo: MultipartUploadInfo
		
		private enum CodingKeys: String, CodingKey {
			case identifier = "id"
			case name
			case size
			case multipartUploadInfo = "multipart"
		}
	}
	
	/// Server side identifier of the transfer
	let id: String // swiftlint:disable:this identifier_name
	
	/// Server side information about the files
	let files: [FileResponse]
}

// MARK: - Create board

/// Parameters used for the create transfer request
struct CreateBoardParameters: Encodable {
	
	struct FileParameters: Encodable {
		let name: String
		let size: UInt64
	}
	/// Name of the transfer to create
	let name: String
	/// Description of the transfer to create
	let description: String?
	
	/// Initializes the parameters with a local transfer object
	///
	/// - Parameter transfer: Transfer object to create on the server
	init(with board: Board) {
		name = board.name
		description = board.description
	}
}

/// Response from create transfer request
struct CreateBoardResponse: Decodable {
	/// Server side identifier of the transfer
	let id: String // swiftlint:disable:this identifier_name
	/// The URL to where the transfer can be found online
	let url: URL
}

// MARK: - Add files

/// Parameters used for the add files request
struct AddFilesParameters: Encodable {
	/// Describes a file to be added to a board
	struct FileParameters: Encodable {
		/// Full name of file (e.g. "photo.jpg")
		let name: String
		/// Filesize in bytes
		let size: UInt64
		
		/// Initializes Item struct with a File struct
		///
		/// - Parameter file: File struct to initialize Item from
		init(with file: File) {
			name = file.filename
			size = file.filesize
		}
	}
	
	/// All items to be added to the transfer
	let files: [FileParameters]
	
	/// Initalizes the parameters with an array of File structs
	///
	/// - Parameter files: Array of File structs to be added to the transfer
	init(with files: [File]) {
		self.files = files.map { file in
			return FileParameters(with: file)
		}
	}
}

/// Response from the add files request
struct AddFilesResponse: Decodable {
	/// Contains information about the chunks and the upload identifier
	struct UploadInfo: Decodable {
		let id: String
		let partNumbers: Int
		let chunkSize: UInt64
	}
	
	/// Identifier of the File on the server
	let id: String
	/// Name of the file
	let name: String
	/// Size of the file in bytes
	let size: Bytes
	/// Upload info for the file
	let multipart: UploadInfo
}

// MARK: - Request upload URL

/// Response from the add upload url request for chunks
struct AddUploadURLResponse: Decodable {
	/// URL to upload the chunk to
	let url: URL
}

// MARK: - Complete upload

/// Parameters used for the complete file upload request
struct CompleteTransferFileUploadParameters: Encodable {
	/// Number of chunks used for the file
	let partNumbers: Int
}

/// Response from complete upload request
struct CompleteBoardFileUploadResponse: Decodable {
	/// Whether the upload of all the chunks has succeeded
	let success: Bool
	/// Message describing either success or failure of chunk uploads
	let message: String
}

// MARK: - Finalize transfer

/// Response for the finalize transfer call
struct FinalizeTransferResponse: Decodable {
	/// Public URL of the finalized transfer
	let url: URL
}
