//
//  RollingOutputView.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/3/9.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import UIKit
import RecordKit

class RollingOutputView: UIView {
	private var _rollingEqualizerView: DPRollingEqualizerView? = nil
	
	override init(frame: CGRect) {
		super.init(frame: .zero)
		
		NotificationCenter.default.addObserver(self, selector: #selector(receivedFloatBuffer), name: Notification.Name.microphoneFloatBuffer, object: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if _rollingEqualizerView == nil, bounds.height != 0 {
			_rollingEqualizerView = DPRollingEqualizerView(frame: bounds, andSettings: DPEqualizerSettings.create(by: .rolling))
			addSubview(_rollingEqualizerView!)
		}
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func receivedFloatBuffer(_ notification: Notification) {
		guard let buffer = UnsafeMutablePointer<Float>.init(mutating: notification.userInfo?["buffer"] as? UnsafePointer<Float>), let bufferSize = notification.userInfo?["bufferSize"] as? UInt32 else { return }
		_rollingEqualizerView?.updateBuffer(buffer, withBufferSize: bufferSize)
	}

	override func draw(_ rect: CGRect) {
		super.draw(rect)
	}
}
