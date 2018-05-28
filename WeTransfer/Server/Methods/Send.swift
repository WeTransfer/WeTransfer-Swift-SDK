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
	
	public static func send(_ transfer: Transfer, stateChanged: @escaping (State) -> Void) {
		
		guard transfer.identifier != nil else {
			stateChanged(.failed(Error.transferNotYetCreated))
			return
		}
		
		let progress = Progress(totalUnitCount: Int64(transfer.files.reduce(0, { $0 + $1.filesize })))
		
		stateChanged(.started(progress))
		
		stateChanged(.created(transfer))
		
		var runningFileUploadIdentifiers = [String]()
		var failedUploadErrors = [Swift.Error]()
		
		for file in transfer.files {
			
			guard let fileIdentifier = file.identifier, !file.chunks.isEmpty else {
				continue
			}
			
			runningFileUploadIdentifiers.append(fileIdentifier)
			
			let fileUploader = FileUploader(with: file)
			fileUploader.upload(with: { (_, totalBytesSent, _) in
				progress.completedUnitCount = totalBytesSent
			}) { (result) in
				switch result {
				case .success(let file):
					// THIS IS HORRIBLE AND SHOULD NEVER BE COMMITTED
					do {
						try complete(file, completion: { (result) in
							if let fileIndex = runningFileUploadIdentifiers.index(of: fileIdentifier) {
								runningFileUploadIdentifiers.remove(at: fileIndex)
							}
							switch result {
							case .success:
								transfer.setFileUploaded(file, uploaded: true)
								if runningFileUploadIdentifiers.isEmpty {
									if let error = failedUploadErrors.first {
										stateChanged(.failed(error))
									} else {
										stateChanged(.completed(transfer))
									}
								}
							case .failure(let error):
								if runningFileUploadIdentifiers.isEmpty {
									stateChanged(.failed(error))
								}
							}
						})
					} catch {
						if let fileIndex = runningFileUploadIdentifiers.index(of: fileIdentifier) {
							runningFileUploadIdentifiers.remove(at: fileIndex)
						}
						failedUploadErrors.append(error)
						if runningFileUploadIdentifiers.isEmpty {
							stateChanged(.failed(error))
						}
					}
				case .failure(let error):
					if let fileIndex = runningFileUploadIdentifiers.index(of: fileIdentifier) {
						runningFileUploadIdentifiers.remove(at: fileIndex)
					}
					failedUploadErrors.append(error)
					if runningFileUploadIdentifiers.isEmpty {
						stateChanged(.failed(error))
					}
				}
			}
		}
	}
	
	struct CompleteTransferResponse: Decodable {
		let ok: Bool
		let message: String
	}
	
	static func complete(_ file: File, completion: @escaping (Result<File>) -> Void) throws {
		guard let identifier = file.identifier else {
			throw Error.transferNotYetCreated
		}
		try request(.completeUpload(fileIdentifier: identifier), completion: { (result: Result<CompleteTransferResponse>) in
			switch result {
			case .success(let completeResponse):
                guard completeResponse.ok else {
                    completion(.failure(RequestError.serverError(errorMessage: completeResponse.message)))
                    return
                }
				completion(.success(file))
			case .failure(let error):
				completion(.failure(error))
			}
		})
	}
}
