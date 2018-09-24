//
//  MainViewController.swift
//  WeTransfer Sample Project
//
//  Created by Pim Coumans on 02/07/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import WeTransfer

/// Single ViewController where the whole transfer progress takes place.
/// Actual logic for configuring the WeTransfer client and performing the transfer is found in the first extension marked 'WeTransfer Logic'
/// To properly authenticate with the client make sure you've created an API key at https://developers.wetransfer.com
final class MainViewController: UIViewController {
	
	/// Used to decide which views should be shown and what the content of the labels should be
	private enum ViewState {
		case ready
		case selectedMedia
		case startedTransfer
		case transferInProgress
		case failed(error: Error)
		case transferCompleted(shortURL: URL)
	}

	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var bodyLabel: UILabel!
	@IBOutlet private var selectButton: UIButton!
	@IBOutlet private var progressView: UIProgressView!
	@IBOutlet private var urlButton: UIButton!
	
	@IBOutlet private var imageView: UIImageView!
	@IBOutlet private var secondImageView: UIImageView!
	
	@IBOutlet private var transferButton: UIButton!
	@IBOutlet private var addMoreButton: RoundedButton!
	@IBOutlet private var shareButton: UIButton!
	@IBOutlet private var newTransferButton: RoundedButton!
	
	@IBOutlet private var mainButtonsStackView: UIStackView!
	@IBOutlet private var contentStackView: UIStackView!
	
	/// Handles presentation of UIImagePickerController
	let picker = MediaPicker()
	
	private var viewState: ViewState = .ready {
		didSet {
			updateInterface()
		}
	}
	
	private var progressObservation: NSKeyValueObservation?
	
	private var selectedMedia = [MediaPicker.Media]() {
		didSet {
			// Update image views whenever media is selected
			imageView.image = selectedMedia.last?.previewImage
			if selectedMedia.count > 1 {
				let image = selectedMedia[selectedMedia.count - 2].previewImage
				secondImageView.image = image
			} else {
				secondImageView.image = nil
			}
		}
	}
	
	/// Holds completed transfer's URL
	private var transferURL: URL?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		newTransferButton.style = .alternative
		addMoreButton.style = .alternative
		
		rotateSecondImage()
		updateInterface()
		configureWeTransfer()
	}
}

// MARK: - WeTransfer Logic
extension MainViewController {
	
	private func configureWeTransfer() {
		// Configures the WeTransfer client with the required API key
		// Get an API key at https://developers.wetransfer.com
		WeTransfer.configure(with: WeTransfer.Configuration(apiKey: "{YOUR_API_KEY_HERE}"))
	}
	
	private func sendTransfer() {
		guard !selectedMedia.isEmpty else {
			return
		}
		viewState = .startedTransfer
		let files = selectedMedia.map({ $0.url })
		
		// Creates a transfer and uploads all provided files
		WeTransfer.uploadTransfer(named: "Sample Transfer", containing: files) { [weak self] state in
			switch state {
			case .uploading(let progress):
				self?.viewState = .transferInProgress
				self?.observeUploadProgress(progress)
			case .failed(let error):
				self?.viewState = .failed(error: error)
			case .completed(let transfer):
				if let url = transfer.shortURL {
					self?.transferURL = url
					self?.viewState = .transferCompleted(shortURL: url)
				}
			default:
				break
			}
		}
	}
	
	private func observeUploadProgress(_ progress: Progress) {
		progressView.observedProgress = progress
		progressObservation = progress.observe(\.fractionCompleted) { [weak self] (progress, _) in
			DispatchQueue.main.async {
				self?.bodyLabel.text = "\(Int(progress.fractionCompleted * 100))% completed"
			}
		}
	}
}

// MARK: - UI Logic
extension MainViewController {
	
	private func rotateSecondImage() {
		let rotation = 2 * (CGFloat.pi / 180)
		secondImageView.transform = CGAffineTransform(rotationAngle: rotation)
	}
	
	private func resetInterface() {
		// Remove UI elements that aren't used everywhere
		[transferButton, addMoreButton, shareButton, newTransferButton].forEach({ (button: UIButton) in
			mainButtonsStackView.removeArrangedSubview(button)
			button.removeFromSuperview()
		})
		
		// Hide views not managed by a UIStackView
		imageView.isHidden = true
		secondImageView.isHidden = true
		
		[selectButton, progressView, urlButton].forEach({ (element: UIView) in
			contentStackView.removeArrangedSubview(element)
			element.removeFromSuperview()
		})
	}
	
	private func updateInterface() {
		resetInterface()
		
		switch viewState {
		case .ready:
			transferButton.setTitle("Transfer", for: .normal)
			mainButtonsStackView.addArrangedSubview(transferButton)
			transferButton.isEnabled = false
			titleLabel.text = "Add media to transfer"
			bodyLabel.text = "Pick a photo to send and get a URL to share wherever you want"
			contentStackView.addArrangedSubview(selectButton)
		case .selectedMedia:
			titleLabel.text = nil
			bodyLabel.text = nil
			imageView.isHidden = false
			secondImageView.isHidden = false
			mainButtonsStackView.addArrangedSubview(addMoreButton)
			mainButtonsStackView.addArrangedSubview(transferButton)
			transferButton.isEnabled = true
		case .startedTransfer:
			titleLabel.text = "Uploading"
			bodyLabel.text = "Preparing transfer..."
			progressView.progress = 0
			contentStackView.addArrangedSubview(progressView)
		case .transferInProgress:
			titleLabel.text = "Uploading"
			contentStackView.addArrangedSubview(progressView)
		case .failed(let error):
			titleLabel.text = "Upload failed"
			bodyLabel.text = error.localizedDescription
			transferButton.setTitle("Retry transfer", for: .normal)
			mainButtonsStackView.addArrangedSubview(transferButton)
		case .transferCompleted(let shortURL):
			titleLabel.text = "Transfer completed"
			bodyLabel.text = nil
			let attributes: [NSAttributedStringKey: Any] = [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
															.foregroundColor: urlButton.currentTitleColor]
			let attributedURLText = NSAttributedString(string: shortURL.absoluteString, attributes: attributes)
			urlButton.setAttributedTitle(attributedURLText, for: .normal)
			contentStackView.addArrangedSubview(urlButton)
			mainButtonsStackView.addArrangedSubview(shareButton)
			mainButtonsStackView.addArrangedSubview(newTransferButton)
		}
	}
}

// MARK: - Button handlers
extension MainViewController {
	
	@IBAction private func didPressSelectButton(_ button: UIButton) {
		picker.show(from: self) { [weak self] (media) in
			if let media = media {
				self?.selectedMedia.append(media)
				self?.viewState = .selectedMedia
			}
		}
	}
	
	@IBAction private func didPressTransferButton(_ button: UIButton) {
		sendTransfer()
	}
	
	@IBAction private func didPressShareButton(_ button: UIButton) {
		guard let url = transferURL else {
			return
		}
		let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
		present(activityViewController, animated: true, completion: nil)
	}
	
	@IBAction private func didPressNewTransferButton(_ button: UIButton) {
		selectedMedia.removeAll()
		viewState = .ready
	}
	
	@IBAction private func didPressURLButton(_ button: UIButton) {
		guard let url = transferURL, UIApplication.shared.canOpenURL(url) else {
			return
		}
		UIApplication.shared.open(url)
	}
}
