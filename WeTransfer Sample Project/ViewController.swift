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
		case transferInProgress(progress: Progress)
		case failed(error: Error)
		case transferCompleted(shortURL: URL)
	}

	@IBOutlet private var titleLabel: UILabel?
	@IBOutlet private var bodyLabel: UILabel?
	@IBOutlet private var selectButton: UIButton?
	@IBOutlet private var progressView: UIProgressView?
	@IBOutlet private var urlLabel: UILabel?
	
	@IBOutlet private var imageView: UIImageView?
	
	@IBOutlet private var transferButton: UIButton?
	@IBOutlet private var addMoreButton: Button?
	@IBOutlet private var shareButton: UIButton?
	@IBOutlet private var newTransferButton: Button?
	
	@IBOutlet private var mainButtonsStackView: UIStackView?
	@IBOutlet private var contentStackView: UIStackView?
	
	let picker = ImagePicker()
	
	private var viewState: ViewState = .ready {
		didSet {
			updateInterface()
		}
	}
	
	private var progressObservation: NSKeyValueObservation?
	
	private var selectedMedia = [URL]() {
		didSet {
			if let imagePath = selectedMedia.last?.path {
				DispatchQueue.global(qos: .userInitiated).async { [weak self] in
					let image = UIImage(contentsOfFile: imagePath)
					DispatchQueue.main.async {
						self?.imageView?.image = image
					}
				}
			}
			if !selectedMedia.isEmpty, case .ready = viewState {
				viewState = .selectedMedia
			}
		}
	}
	
	private var transferURL: URL?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		updateInterface()
		newTransferButton?.style = .alternative
		addMoreButton?.style = .alternative
		WeTransfer.configure(with: WeTransfer.Configuration(apiKey: "{YOUR_API_KEY_HERE}"))
	}
	
	private func resetInterface() {
		// Remove UI elements that aren't used everywhere
		[transferButton, addMoreButton, shareButton, newTransferButton].compactMap({ $0 }).forEach({ button in
			mainButtonsStackView?.removeArrangedSubview(button)
			button.removeFromSuperview()
		})
		[selectButton, progressView, urlLabel].compactMap({ $0 }).forEach({ element in
			contentStackView?.removeArrangedSubview(element)
			element.removeFromSuperview()
		})
		contentStackView?.isHidden = true
		imageView?.isHidden = true
	}
	
	private func updateInterface() {
		resetInterface()
		
		switch viewState {
		case .ready:
			if let transferButton = transferButton {
				mainButtonsStackView?.addArrangedSubview(transferButton)
				transferButton.isEnabled = false
			}
			contentStackView?.isHidden = false
			titleLabel?.text = "Add media to transfer"
			bodyLabel?.text = "Pick a photo to send and get a URL to share wherever you want"
			if let selectButton = selectButton {
				contentStackView?.addArrangedSubview(selectButton)
			}
		case .selectedMedia:
			imageView?.isHidden = false
			if let addMoreButton = addMoreButton {
				mainButtonsStackView?.addArrangedSubview(addMoreButton)
			}
			if let transferButton = transferButton {
				mainButtonsStackView?.addArrangedSubview(transferButton)
				transferButton.isEnabled = true
			}
		case .startedTransfer:
			contentStackView?.isHidden = false
			titleLabel?.text = "Uploading"
			bodyLabel?.text = "Preparing transfer..."
			
			if let progressView = progressView {
				progressView.progress = 0
				contentStackView?.addArrangedSubview(progressView)
			}
		case .transferInProgress(let progress):
			contentStackView?.isHidden = false
			titleLabel?.text = "Uploading"
			
			self.progressObservation = progress.observe(\.fractionCompleted) { [weak self] (progress, _) in
				DispatchQueue.main.async {
					self?.bodyLabel?.text = "\(Int(progress.fractionCompleted * 100))% completed"
				}
			}
			if let progressView = progressView {
				contentStackView?.addArrangedSubview(progressView)
				progressView.observedProgress = progress
			}
		case .failed(let error):
			contentStackView?.isHidden = false
			titleLabel?.text = "Upload failed"
			bodyLabel?.text = error.localizedDescription
			if let transferButton = transferButton {
				mainButtonsStackView?.addArrangedSubview(transferButton)
			}
		case .transferCompleted(let shortURL):
			contentStackView?.isHidden = false
			titleLabel?.text = "Transfer completed"
			bodyLabel?.text = nil
			
			if let urlLabel = urlLabel {
				urlLabel.text = shortURL.absoluteString
				contentStackView?.addArrangedSubview(urlLabel)
			}
			if let shareButton = shareButton {
				mainButtonsStackView?.addArrangedSubview(shareButton)
			}
			if let newTransferButton = newTransferButton {
				mainButtonsStackView?.addArrangedSubview(newTransferButton)
			}
		}
	}
	
	@IBAction private func didPressSelectButton(_ button: UIButton) {
		picker.show(from: self) { (items) in
			if let media = items {
				self.selectedMedia.append(contentsOf: media)
			}
		}
	}
	
	@IBAction private func didPressTransferButton(_ button: UIButton) {
		guard !selectedMedia.isEmpty else {
			return
		}
		viewState = .startedTransfer
		WeTransfer.uploadTransfer(named: "Sample Transfer", containing: selectedMedia) { [weak self] state in
			switch state {
			case .uploading(let progress):
				self?.viewState = .transferInProgress(progress: progress)
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
}
