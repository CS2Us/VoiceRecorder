//
//  UIFont+Extension.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/2/26.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
	static func pingFangSCLight(fontSize: CGFloat) -> UIFont {
		return UIFont(name: "PingFangSC-Light", size: fontSize)!
	}
	
	static func pingFangSCRegular(fontSize: CGFloat) -> UIFont {
		return UIFont(name: "PingFangSC-Regular", size: fontSize)!
	}
	
	static func pingFangSCMedium(fontSize: CGFloat) -> UIFont {
		return UIFont(name: "PingFangSC-Medium", size: fontSize)!
	}
	
	static func pingFangTCLight(fontSize: CGFloat) -> UIFont {
		return UIFont(name: "PingFangTC-Light", size: fontSize)!
	}
}
