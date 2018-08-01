//
//  Button.swift
//  WeTransfer Sample Project
//
//  Created by Pim Coumans on 19/07/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// Button with colored background and rounded corners
final class RoundedButton: UIButton {
	
	enum Style {
		case regular
		case alternative
	}
	
	private let horizontalPadding: CGFloat = 22
	private let minimumHeight: CGFloat = 44
	
	var style: Style = .regular {
		didSet {
			updateBackgroundColor()
			updateTitleColor()
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		layer.cornerRadius = 8
		updateBackgroundColor()
		updateTitleColor()
		titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
		
		heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight).isActive = true
		contentEdgeInsets = UIEdgeInsets(top: 0, left: horizontalPadding, bottom: 0, right: horizontalPadding)
	}
	
	override var isEnabled: Bool {
		didSet {
			updateBackgroundColor()
			updateTitleColor()
		}
	}
	
	private func updateBackgroundColor() {
		if isEnabled {
			let enabledColor = UIColor(red: 64 / 255, green: 159 / 255, blue: 255 / 255, alpha: 1)
			let alternativeColor = UIColor(white: 235 / 255, alpha: 1)
			backgroundColor = style == .alternative ? alternativeColor : enabledColor
		} else {
			backgroundColor = UIColor(red: 165 / 255, green: 168 / 255, blue: 172 / 255, alpha: 1)
		}
		
	}
	
	private func updateTitleColor() {
		let titleColor = UIColor.white
		let alternativeTitleColor = UIColor(white: 75 / 255, alpha: 1)
		setTitleColor(style == .alternative ? alternativeTitleColor : titleColor, for: .normal)
	}
	
}
