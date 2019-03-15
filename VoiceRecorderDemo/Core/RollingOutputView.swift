//
//  RollingOutputView.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/3/9.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import RecordKit

class RollingOutputView: RKRollingPlot {
	override var setting: RKRollingPlotSetting {
		let setting = RKRollingPlotSetting()
		setting.numOfBins = 10
		return setting
	}
}
