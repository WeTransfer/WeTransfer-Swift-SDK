//
//  Send.swift
//  WeTransfer
//
//  Created by Pim Coumans on 02/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation



extension WeTransfer {
	
	public enum State {
		// Upload has started, track progress with progress object
		case started(Progress)
		// Transfer is created server side, share url is available
		case created(Transfer)
		// Transfer is completed
		case completed(Transfer)
		// Transfer failed due to provided error
		case failed(Swift.Error)
	}
	
	public static func send(_ transfer: Transfer, stateChanged: @escaping (State) -> Void) throws {
		
		guard let _ = transfer.identifier else {
			throw Error.transferNotYetCreated
		}
		
		let progress = Progress(totalUnitCount: Int64(transfer.files.reduce(0, { $0 + $1.filesize })))
		stateChanged(.started(progress))
		
		stateChanged(.created(transfer))
		
		var runningFileUploadIdentifiers = [String]()
		var failedUploadErrors = [Swift.Error]()
		
		for file in transfer.files {
			
			guard let fileIdentifier = file.identifier else {
				continue
			}
			runningFileUploadIdentifiers.append(fileIdentifier)
			
			var runningChunkUploadIdentifiers = [String]()
			
			for chunk in file.chunks {
				guard let data = try? chunk.data() else {
					return
				}
				runningChunkUploadIdentifiers.append(chunk.uploadIdentifier)
				let endpoint: APIEndpoint = .upload(url: chunk.uploadURL)
				var urlRequest = URLRequest(url: endpoint.url)
				urlRequest.httpMethod = endpoint.method.rawValue
				let uploadTask = client.urlSession.uploadTask(with: urlRequest, from: data) { (data, urlResponse, error) in
					if let chunkIndex = runningChunkUploadIdentifiers.index(of: chunk.uploadIdentifier) {
						runningChunkUploadIdentifiers.remove(at: chunkIndex)
					}
					if runningChunkUploadIdentifiers.isEmpty {
						do {
							try complete(file, completion: { (result) in
								if let fileIndex = runningFileUploadIdentifiers.index(of: fileIdentifier) {
									runningFileUploadIdentifiers.remove(at: fileIndex)
								}
								switch result {
								case .success: //.success(let file)
									if runningFileUploadIdentifiers.isEmpty {
										if let error = failedUploadErrors.last {
											stateChanged(.failed(error))
										} else {
											stateChanged(.completed(transfer))
										}
									}
								case .failure(let error):
									failedUploadErrors.append(error)
									if runningFileUploadIdentifiers.isEmpty {
										stateChanged(.failed(error))
									}
								}
							})
						} catch {
							stateChanged(.failed(error))
						}
					}
				}
				progress.addChild(uploadTask.progress, withPendingUnitCount: Int64(chunk.chunkSize))
				uploadTask.resume()
			}
		}
	}
	
	internal struct CompleteTransferResponse: Decodable {
		let ok: Bool
		let message: String
	}
	
	public static func complete(_ file: File, completion: @escaping (Result<File>) -> Void) throws {
		guard let identifier = file.identifier else {
			throw Error.transferNotYetCreated
		}
		try request(.completeUpload(fileIdentifier: identifier), completion: { (result: Result<CompleteTransferResponse>) in
			switch result {
			case .success(let completeResponse):
				print("HUZZAH: \(completeResponse)")
				completion(.success(file))
			case .failure(let error):
				completion(.failure(error))
			}
		})
	}
}
