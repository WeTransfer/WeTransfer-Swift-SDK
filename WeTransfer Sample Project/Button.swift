//
//  Button.swift
//  WeTransfer Sample Project
//
//  Created by Pim Coumans on 19/07/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

final class Button: UIButton {
	
	enum Style {
		case regular
		case alternative
	}
	
	var style: Style = .regular {
		didSet {
			updateBackgroundColor()
			updateTitleColor()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		layer.cornerRadius = 8
		updateBackgroundColor()
		updateTitleColor()
		titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
	}
	
	override var isEnabled: Bool {
		didSet {
			updateBackgroundColor()
			updateTitleColor()
		}
	}
	
	private func updateBackgroundColor() {
		let enabledColor = UIColor(red: 64 / 255, green: 159 / 255, blue: 255 / 255, alpha: 1)
		let alternativeColor = UIColor(white: 235 / 255, alpha: 1)
		let disabledColor = UIColor(red: 165 / 255, green: 168 / 255, blue: 172 / 255, alpha: 1)
		backgroundColor = isEnabled ? (style == .alternative ? alternativeColor : enabledColor) : disabledColor
		
	}
	
	private func updateTitleColor() {
		let titleColor = UIColor.white
		let alternativeTitleColor = UIColor(white: 75 / 255, alpha: 1)
		setTitleColor(style == .alternative ? alternativeTitleColor : titleColor, for: .normal)
	}
	
	override var intrinsicContentSize: CGSize {
		var contentSize = super.intrinsicContentSize
		if contentSize.width == titleRect(forContentRect: bounds).width {
			contentSize.width += 44
		}
		contentSize.height = 44
		return contentSize
	}
	
}
