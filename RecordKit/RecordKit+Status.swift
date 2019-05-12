//
//  RecordKit+Status.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

extension RecordKit {
	public internal(set) static var shouldBeRunning: Bool = false
	
	#if os(iOS)
	var isIAAConnected: Bool {
		do {
			let result: UInt32? = try RecordKit.engine.outputNode.audioUnit?.getValue(forProperty: kAudioUnitProperty_IsInterAppConnected)
			return result == 1
		} catch {
			RKLog("could not get IAA status: \(error)")
		}
		return false
	}
	#endif
}
