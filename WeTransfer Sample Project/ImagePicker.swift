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
final class ImagePicker: NSObject {
	
	typealias ItemHandler = ([URL]?) -> Void
	
	private var itemHandler: ItemHandler?
	private var presentedImagePickerControler: UIImagePickerController?
	
	func show(from viewController: UIViewController, itemHandler: @escaping ItemHandler) {
		guard self.itemHandler == nil else {
			return
		}
		self.itemHandler = itemHandler
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
	
	func authorize(with completion: @escaping (Bool) -> Void) {
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
	
	func finish(with items: [URL]?) {
		itemHandler?(items)
		itemHandler = nil
		presentedImagePickerControler?.presentingViewController?.dismiss(animated: true, completion: nil)
		presentedImagePickerControler = nil
	}
}

extension ImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		finish(with: nil)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
		guard let url = info[UIImagePickerControllerImageURL] as? URL ?? info[UIImagePickerControllerMediaURL] as? URL else {
			finish(with: nil)
			return
		}
		finish(with: [url])
	}
}
