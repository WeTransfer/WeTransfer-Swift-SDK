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

	@IBOutlet private var statusLabel: UILabel?
	@IBOutlet private var progressView: UIProgressView?
	@IBOutlet private var addButton: UIButton?
	@IBOutlet private var uploadButton: UIButton?
	
	private var progressObservation: NSKeyValueObservation?
	
	private var selectedMedia = [URL]() {
		didSet {
			updateInterface()
		}
	}
	
	private var completedTransfer: Transfer? {
		didSet {
			updateInterface()
		}
	}
	
	let picker = Picker()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		updateInterface()
		WeTransfer.configure(with: WeTransfer.Configuration(apiKey: "{YOUR API KEY HERE}"))
	}
	
	@IBAction func didPressAddButton(_ button: UIButton) {
		picker.show(from: self) { (items) in
			if let media = items {
				self.selectedMedia.append(contentsOf: media)
			}
		}
	}
	
	@IBAction func didPressUploadButton(_ button: UIButton) {
		guard !selectedMedia.isEmpty else {
			return
		}
		
		guard completedTransfer == nil else {
			selectedMedia.removeAll()
			UIPasteboard.general.url = completedTransfer?.shortURL
			completedTransfer = nil
			statusLabel?.text = "Link copied!"
			return
		}
		
		statusLabel?.textColor = .black
		statusLabel?.text = "Starting transfer..."
		uploadButton?.isEnabled = false
		addButton?.isEnabled = false
		
		WeTransfer.sendTransfer(named: "Sample Transfer", files: selectedMedia) { [weak self] (state) in
			switch state {
			case .created:
				self?.statusLabel?.text = "Transfer created..."
			case .inProgress(let progress):
				self?.progressView?.observedProgress = progress
				self?.progressObservation = progress.observe(\.fractionCompleted, changeHandler: { (progress, _) in
					DispatchQueue.main.async {
						self?.statusLabel?.text = "\(Int(progress.fractionCompleted * 100))% uploaded"
					}
				})
			case .failed(let error):
				self?.statusLabel?.textColor = .red
				self?.statusLabel?.text = "Error: \(error.localizedDescription)"
				self?.progressView?.observedProgress = nil
			case .completed(let transfer):
				self?.progressView?.observedProgress = nil
				guard let URL = transfer.shortURL else {
					self?.statusLabel?.text = "Transfer complete but no URL??"
					return
				}
				self?.completedTransfer = transfer
				self?.statusLabel?.text = URL.absoluteString
			}
		}
	}
	
	private func updateInterface() {
		guard completedTransfer == nil else {
			uploadButton?.setTitle("Copy Link", for: .normal)
			uploadButton?.isEnabled = true
			return
		}
		
		addButton?.isEnabled = true
		uploadButton?.setTitle("Upload 🚀", for: .normal)
		
		guard !selectedMedia.isEmpty else {
			uploadButton?.isEnabled = false
			statusLabel?.text = "Add media to transfer"
			return
		}
		uploadButton?.isEnabled = true
		
		let singularPlural = selectedMedia.count == 1 ? "item" : "items"
		statusLabel?.text = "Added \(selectedMedia.count) \(singularPlural) to transfer"
	}
}
