//
//  ViewController.swift
//  WeTransfer Sample Project
//
//  Created by Pim Coumans on 02/07/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import WeTransfer

class ViewController: UIViewController {

	@IBOutlet var uploadButton: UIButton?
	@IBOutlet var progressView: UIProgressView?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		WeTransfer.configure(with: .init(apiKey: "{YOUR API KEY HERE}"))
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func didPressUploadButton(_ button: UIButton) {
		uploadButton?.isEnabled = false
		let files = [URL]()
		WeTransfer.sendTransfer(named: "Sample Transfer", files: files) { (state) in
			switch state {
			case .inProgress(let progress):
				self.progressView?.observedProgress = progress
			default:
				print("DEFAULT")
			}
			print("state: \(state)")
		}
		
	}
}
