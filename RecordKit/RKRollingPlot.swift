//
//  RKRollingPlot.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import Accelerate
import CoreAudio

open class RKRollingPlot: UIView {
	open var setting: RKRollingPlotSetting {
		let setting = RKRollingPlotSetting()
		setting.numOfBins = 10
		return setting
	}
	private var service: RKRollingPlotService
	
	public override init(frame: CGRect) {
		service = RKRollingPlotService()
		super.init(frame: frame)
		service.setting = setting
		
		NotificationCenter.default.addObserver(self, selector: #selector(audioReceived(bufferList:bufferSize:)), name: .microphoneBufferList, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(audioReceived(floatBuffer:bufferSize:)), name: .microphoneFloatBuffer, object: nil)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		service = RKRollingPlotService()
		super.init(coder: aDecoder)
		service.setting = setting
	}
	
	override open func draw(_ rect: CGRect) {
		let ctx = UIGraphicsGetCurrentContext()
		ctx?.saveGState()
		ctx?.fill(bounds)
		
		let columnWidth = bounds.size.width / CGFloat(setting.numOfBins - 1)
		let actualWidth = max(0, columnWidth * (1 - 2 * setting.padding))
		let actualPadding = max(0, (columnWidth - actualWidth) / 2)
		
		for i in 0..<setting.numOfBins {
//			let columnHeight = 
		}
	}
}

extension RKRollingPlot {
	@objc(audioReceivedBufferList:bufferSize:)
	private func audioReceived(bufferList: UnsafePointer<AudioBuffer>, bufferSize: UInt32) {
//		service.update(floatBuffer, with: bufferSize)
	}
	
	@objc(audioReceivedFloatBuffer:bufferSize:)
	private func audioReceived(floatBuffer: UnsafePointer<Float>, bufferSize: UInt32) {
		service.update(floatBuffer, with: bufferSize)
	}
}

