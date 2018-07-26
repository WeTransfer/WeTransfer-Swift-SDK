//
//  MainViewController.swift
//  WeTransfer Sample Project
//
//  Created by Pim Coumans on 02/07/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import WeTransfer

final class MainViewController: UIViewController {
	
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
	@IBOutlet private var urlButton: UIButton!
	
	@IBOutlet private var imageView: UIImageView!
	@IBOutlet private var secondImageView: UIImageView!
	
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
			imageView.image = selectedMedia.last?.previewImage
			if selectedMedia.count > 1 {
				let image = selectedMedia[selectedMedia.count - 2].previewImage
				secondImageView.image = image
			} else {
				secondImageView.image = nil
			}
		}
	}
	
	private var transferURL: URL?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		newTransferButton.style = .alternative
		addMoreButton.style = .alternative
		
		let rotation = 2 * (CGFloat.pi / 180)
		secondImageView.transform = CGAffineTransform(rotationAngle: rotation)
		
		updateInterface()
		WeTransfer.configure(with: WeTransfer.Configuration(apiKey: "miKoFL1pcG3NGp8eQxdbw2IaNDGU8ueP3rM23q1v"))
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
	
	@IBAction private func didPressURLButton(_ button: UIButton) {
		guard let url = transferURL, UIApplication.shared.canOpenURL(url) else {
			return
		}
		UIApplication.shared.open(url)
	}
}
