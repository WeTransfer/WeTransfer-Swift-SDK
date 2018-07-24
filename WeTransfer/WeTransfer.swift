//
//  WeTransfer.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Main struct exposing all entrypoints for the API.
/// Configure the client with `WeTransfer.configure()` after which all request are available.
/// - Use `WeTransfer.sendTransfer()` to send a transfer right away
/// - Use `WeTransfer.createTransfer()` to manually create a transfer on the server and `WeTransfer.send()` to upload the transfer when you're ready
public struct WeTransfer {

	/// The client used for all requests. Stores the authenticated state and creates and manages all requests
	static var client: APIClient = APIClient()
	
	private init() {}
}

extension WeTransfer {

	/// Possible errors thrown from multiple points in the transfer progress
	public enum Error: Swift.Error, LocalizedError {
		/// WeTransfer client not configured yet, make sure to call `WeTransfer.configure(with configuration:)`
		case notConfigured
		/// Authorization failed when performing request
		case notAuthorized
		/// Transfer is already created so create transfer request should not be called again
		case transferAlreadyCreated
		/// Transfer is not yet created so other request regarding the transfer will fail
		case transferNotYetCreated
		/// Transfer has no files to share as no files are added yet or all files are already uploaded
		case noFilesAvailable
		
		public var errorDescription: String? {
			switch self {
			case .notConfigured:
				return "Framework should configured with at least an API key"
			case .notAuthorized:
				return "Not authorized: invalid API key used for request"
			case .transferAlreadyCreated:
				return "Transfer already created: create transfer request should not be called multiple times for the same transfer"
			case .noFilesAvailable:
				return "No files available or all files have already been uploaded: add files to the transfer to upload"
			default:
				return "\(self)"
			}
		}
	}

	/// Configuration of the API client
	public struct Configuration {
		public let apiKey: String
		public let baseURL: URL
		
		/// Initializes the configuration struct with an API key and optionally a baseURL for when you're pointing to a different server
		///
		/// - Parameters:
		///   - APIKey: Key required to make use of the API. Visit https://developers.wetransfer.com to get a key
		///   - baseURL: Defaults to the standard API, but can be used to point to a different server
		public init(apiKey: String, baseURL: URL? = nil) {
			// swiftlint:disable force_unwrapping
			self.baseURL = baseURL ?? URL(string: "https://dev.wetransfer.com/v1/")!
			self.apiKey = apiKey
		}
	}

	/// Configures the API client with the provided configuration
	///
	/// - Parameter configuration: Configuration struct to configure the API client with
	public static func configure(with configuration: Configuration) {
		client.apiKey = configuration.apiKey
		client.baseURL = configuration.baseURL
	}
}

extension WeTransfer {

	/// Immediately uploads files to a transfer with the provided name and file URLs
	///
	/// - Parameters:
	///   - name: Name of the transfer, shown when user opens the resulting link
	///   - fileURLS: Array of URLs pointing to files to be added to the transfer
	///   - stateChanged: Closure that will be called for state updates.
	///   - state: Enum describing the current transfer's state. See the `State` enum description for more details for each state
	/// - Returns: Transfer object used to handle the transfer process.
	@discardableResult
	public static func uploadTransfer(named name: String, containing fileURLS: [URL], stateChanged: @escaping (_ state: State) -> Void) -> Transfer? {
		
		// Make sure stateChanges closure is called on the main thread
		let changeState = { state in
			DispatchQueue.main.async {
				stateChanged(state)
			}
		}
		
		// Create the transfer model
		let files: [File]
		do {
			files = try fileURLS.compactMap { url in try File(url: url) }
		} catch {
			changeState(.failed(error))
			return nil
		}
		let transfer = Transfer(name: name, description: nil, files: files)
		
		// Create transfer on server
		let creationOperation = CreateTransferOperation(transfer: transfer)
		
		// Add files to the transfer
		let addFilesOperation = AddFilesOperation()
		
		// Upload all files from the chunks
		let uploadFilesOperation = UploadFilesOperation()
		
		// Handle transfer created result
		creationOperation.onResult = { result in
			if case .success(let transfer) = result {
				changeState(.created(transfer))
			}
		}
		
		// When all files are ready for upload
		addFilesOperation.onResult = { result in
			if case .success = result {
				changeState(.uploading(uploadFilesOperation.progress))
			}
		}
		
		// Perform all operations in a chain
		let operations = [creationOperation, addFilesOperation, uploadFilesOperation].chained()
		client.operationQueue.addOperations(operations, waitUntilFinished: false)
		
		// Handle the result of the very last operation that's executed
		uploadFilesOperation.onResult = { result in
			switch result {
			case .failure(let error):
				changeState(.failed(error))
			case .success(let transfer):
				changeState(.completed(transfer))
			}
		}
		
		return transfer
	}
}
