//
//  ViewController.swift
//  WeTransfer Sample Project
//
//  Created by Pim Coumans on 02/07/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import WeTransfer

final class ViewController: UIViewController {
	
	enum ViewState {
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
	@IBOutlet private var urlLabel: UILabel!
	
	@IBOutlet private var imageView: UIImageView!
	
	@IBOutlet private var transferButton: UIButton!
	@IBOutlet private var addMoreButton: RoundedButton!
	@IBOutlet private var shareButton: UIButton!
	@IBOutlet private var newTransferButton: RoundedButton!
	
	@IBOutlet private var mainButtonsStackView: UIStackView!
	@IBOutlet private var contentStackView: UIStackView!
	
	let picker = MediaPicker()
	
	private var viewState: ViewState = .ready {
		didSet {
			updateInterface()
		}
	}
	
	private var progressObservation: NSKeyValueObservation?
	
	private var selectedMedia = [MediaPicker.Media]() {
		didSet {
			if let image = selectedMedia.last?.previewImage {
				imageView.image = image
			}
		}
	}
	
	private var transferURL: URL?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		newTransferButton.style = .alternative
		addMoreButton.style = .alternative
		urlLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapURLLabel(_:))))
		urlLabel.isUserInteractionEnabled = true
		updateInterface()
		WeTransfer.configure(with: WeTransfer.Configuration(apiKey: "{YOUR_API_KEY_HERE}"))
	}
	
	private func resetInterface() {
		// Remove UI elements that aren't used everywhere
		[transferButton, addMoreButton, shareButton, newTransferButton].forEach({ (button: UIButton) in
			mainButtonsStackView.removeArrangedSubview(button)
			button.removeFromSuperview()
		})
		
		[selectButton, progressView, urlLabel].forEach({ (element: UIView) in
			contentStackView.removeArrangedSubview(element)
			element.removeFromSuperview()
		})
		imageView.isHidden = true
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
			imageView.isHidden = false
			titleLabel.text = nil
			bodyLabel.text = nil
			mainButtonsStackView.addArrangedSubview(addMoreButton)
			mainButtonsStackView.addArrangedSubview(transferButton)
			transferButton.isEnabled = true
		case .startedTransfer:
			titleLabel.text = "Uploading"
			bodyLabel.text = "Preparing transfer..."
			progressView.progress = 0
			contentStackView.addArrangedSubview(progressView)
		case .transferInProgress:
			contentStackView.isHidden = false
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
			let attributes = [NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue]
			let attributedURLText = NSAttributedString(string: shortURL.absoluteString, attributes: attributes)
			urlLabel.attributedText = attributedURLText
			contentStackView.addArrangedSubview(urlLabel)
			mainButtonsStackView.addArrangedSubview(shareButton)
			mainButtonsStackView.addArrangedSubview(newTransferButton)
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
	
	@IBAction private func didPressSelectButton(_ button: UIButton) {
		picker.show(from: self) { [weak self] (media) in
			if let media = media {
				self?.selectedMedia.append(media)
				self?.viewState = .selectedMedia
			}
		}
	}
	
	@IBAction private func didPressTransferButton(_ button: UIButton) {
		guard !selectedMedia.isEmpty else {
			return
		}
		viewState = .startedTransfer
		let files = selectedMedia.map({ $0.url })
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
	
	@objc private func didTapURLLabel(_ recognizer: UITapGestureRecognizer) {
		guard let url = transferURL, UIApplication.shared.canOpenURL(url) else {
			return
		}
		UIApplication.shared.open(url)
	}
}
