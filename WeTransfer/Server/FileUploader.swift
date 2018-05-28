//
//  FileUploader.swift
//  WeTransfer
//
//  Created by Pim Coumans on 03/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

class FileUploader: NSObject {

	typealias UploadProgressHandler = (_ bytesSent: Int64, _ totalBytesSent: Int64, _ totalBytes: Int64) -> Void

	enum FileUploaderError: Swift.Error {
		case fileNotPublic
	}

	let file: File
	lazy var urlSession: URLSession = {
		return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
	}()

	let progress: Progress
	var progressHandler: UploadProgressHandler?

	private var tasks: [URLSessionUploadTask] = []

	init(with file: File) {
		self.file = file
		progress = Progress(totalUnitCount: Int64(file.filesize))
	}

	func upload(with progress: UploadProgressHandler?, completion: @escaping (Result<File>) -> Void) {
		progressHandler = progress
		guard file.identifier != nil, !file.chunks.isEmpty else {
			completion(.failure(FileUploaderError.fileNotPublic))
			return
		}
		for chunk in file.chunks {
			guard let data = try? chunk.data() else {
				continue
			}

			let endpoint: APIEndpoint = .upload(url: chunk.uploadURL)
			var urlRequest = URLRequest(url: chunk.uploadURL)
			urlRequest.httpMethod = endpoint.method.rawValue

			var uploadErrors = [Error]()

			let task = urlSession.uploadTask(with: urlRequest, from: data, completionHandler: { (_, _, error) in
				if let error = error {
					uploadErrors.append(error)
				}
				if let taskIndex = self.tasks.index(where: { $0.originalRequest == urlRequest }) {
					self.tasks.remove(at: taskIndex)
				}

				if self.tasks.isEmpty {
					if let error = uploadErrors.last {
						completion(.failure(error))
					} else {
						completion(.success(self.file))
					}
				}
			})
			tasks.append(task)
			task.resume()
		}
	}
}

extension FileUploader: URLSessionTaskDelegate {
	func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
		progress.completedUnitCount += bytesSent
		progressHandler?(bytesSent, progress.completedUnitCount, Int64(file.filesize))
	}
}
