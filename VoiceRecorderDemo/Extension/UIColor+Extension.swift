//
//  UIColor+Extension.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/2/26.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import UIKit

private extension Int {
	func duplicate4bits() -> Int {
		return (self << 4) + self
	}
}

private extension UIColor {
	private convenience init?(hex6: Int, alpha: Float) {
		self.init(red:   CGFloat( (hex6 & 0xFF0000) >> 16 ) / 255.0,
				  green: CGFloat( (hex6 & 0x00FF00) >> 8 ) / 255.0,
				  blue:  CGFloat( (hex6 & 0x0000FF) >> 0 ) / 255.0, alpha: CGFloat(alpha))
	}

	convenience init?(hex: Int, alpha: Float) {
		if (0x000000 ... 0xFFFFFF) ~= hex {
			self.init(hex6: hex, alpha: alpha)
		} else {
			self.init()
			return nil
		}
	}
}

extension UIColor {
	struct Green {
		/** 0x50C878, alpha: 1 **/
		public static var c0: UIColor = UIColor.init(hex: 0x50C878, alpha: 1)!
	}
	
	struct Gray {
		/** 0x333333, alpha: 1 **/
		public static var c0: UIColor = UIColor.init(hex: 0x333333, alpha: 1)!
		/** 0xE6E6E6, alpha: 1 **/
		public static var c1: UIColor = UIColor.init(hex: 0xE6E6E6, alpha: 1)!
		/** 0x999999, alpha: 1 **/
		public static var c2: UIColor = UIColor.init(hex: 0x999999, alpha: 1)!
	}
}
