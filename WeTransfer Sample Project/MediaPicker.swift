//
//  Picker.swift
//  WeTransfer Sample Project
//
//  Created by Pim Coumans on 12/07/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
import Photos

/// Basic wrapper for UIImagePickerController to handle authorization and configuring and presenting the controller
final class MediaPicker: NSObject {
	
	struct Media {
		let url: URL
		let previewImage: UIImage
	}
	
	typealias PickedMediaHandler = (_ media: Media?) -> Void
	
	private var mediaHandler: PickedMediaHandler?
	private var presentedImagePickerControler: UIImagePickerController?
	
	func show(from viewController: UIViewController, mediaHandler: @escaping PickedMediaHandler) {
		guard self.mediaHandler == nil else {
			return
		}
		self.mediaHandler = mediaHandler
		authorize { [weak self] (succeeded) in
			guard succeeded, UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
				self?.finish(with: nil)
				return
			}
			self?.presentImagePicker(from: viewController)
		}
	}
	
	private func presentImagePicker(from viewController: UIViewController) {
		let imagePickerController = UIImagePickerController()
		imagePickerController.delegate = self
		imagePickerController.sourceType = .photoLibrary
		if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
			imagePickerController.mediaTypes = mediaTypes
		}
		viewController.present(imagePickerController, animated: true, completion: nil)
		presentedImagePickerControler = imagePickerController
	}
	
	private func authorize(with completion: @escaping (Bool) -> Void) {
		switch PHPhotoLibrary.authorizationStatus() {
		case .authorized:
			completion(true)
		case .denied, .restricted:
			completion(false)
		case .notDetermined:
			PHPhotoLibrary.requestAuthorization { (status) in
				guard status == .authorized else {
					completion(false)
					return
				}
				completion(true)
			}
		}
	}
	
	private func finish(with item: URL?) {
		guard let url = item else {
			mediaHandler?(nil)
			dismissPickerController()
			return
		}
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			var pickedMedia: Media?
			let asset = AVAsset(url: url)
			if asset.duration.seconds > 0 {
				// Get first frame if video
				let imageGenerator = AVAssetImageGenerator(asset: asset)
				imageGenerator.appliesPreferredTrackTransform = true
				if let image = try? imageGenerator.copyCGImage(at: kCMTimeZero, actualTime: nil) {
					pickedMedia = Media(url: url, previewImage: UIImage(cgImage: image))
				}
			} else {
				if let image = UIImage(contentsOfFile: url.path) {
					pickedMedia = Media(url: url, previewImage: image)
				}
			}
			DispatchQueue.main.async {
				self?.mediaHandler?(pickedMedia)
				self?.dismissPickerController()
			}
		}
	}
	
	private func dismissPickerController() {
		mediaHandler = nil
		presentedImagePickerControler?.presentingViewController?.dismiss(animated: true, completion: nil)
		presentedImagePickerControler = nil
	}
}

extension MediaPicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		finish(with: nil)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
		guard let url = info[UIImagePickerControllerImageURL] as? URL ?? info[UIImagePickerControllerMediaURL] as? URL else {
			finish(with: nil)
			return
		}
		finish(with: url)
	}
}
