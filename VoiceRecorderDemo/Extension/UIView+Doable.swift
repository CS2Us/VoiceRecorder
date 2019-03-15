//
//  UIView+Doable.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/2/26.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import UIKit

protocol Doable {}
extension Doable {
	@discardableResult
	func `do`(_ block: (Self) -> Void) -> Self {
		block(self)
		return self
	}
}

extension UIView: Doable {}
