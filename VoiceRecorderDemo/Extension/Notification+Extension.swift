//
//  Notification+Extension.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/2/27.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

extension Notification.Name {
	static let audioRecordUpdateNotification = Notification.Name("AudioRecordUpdateNotification")
	static let audioRecordStopNotification = Notification.Name("AudioRecordingNotification")
	static let audioRecordFinishNotification = Notification.Name("AudioRecordFinishNotification")
	static let audioRecordFailNotification = Notification.Name("AudioRecordFailNotification")
}

protocol NotificationConvertible {
	func asNotification() -> Notification
}

extension NotificationCenter {
	func post(notification: NotificationConvertible) {
		post(notification.asNotification())
	}
}

/** metering did update **/
struct AudioRecordUpdateNotification: NotificationConvertible {
	static let name: Notification.Name = .audioRecordUpdateNotification
	
	struct UpdateInfo {
		var meteringLevelPercentage: Float
	}
	
	var updateInfo: UpdateInfo
	
	func asNotification() -> Notification {
		return Notification(name: .audioRecordUpdateNotification, object: nil, userInfo: ["updateInfo": updateInfo])
	}
}

extension Notification {
	func toAudioUpdateNotification() -> AudioRecordUpdateNotification? {
		guard name == .audioRecordUpdateNotification,
			let updateInfo = userInfo?["updateInfo"] as? AudioRecordUpdateNotification.UpdateInfo else {
			return nil
		}
		return AudioRecordUpdateNotification(updateInfo: updateInfo)
	}
}

/** metering did stop **/
struct AudioRecordStopNotification: NotificationConvertible {
	static let name: Notification.Name = .audioRecordStopNotification
	
	struct StopInfo {
		
	}
	
	var stopInfo: StopInfo
	
	func asNotification() -> Notification {
		return Notification(name: .audioRecordStopNotification, object: nil, userInfo: ["stopInfo": stopInfo])
	}
}

extension Notification {
	func toAudioStopNotification() -> AudioRecordStopNotification? {
		guard name == .audioRecordStopNotification,
			let stopInfo = userInfo?["stopInfo"] as? AudioRecordStopNotification.StopInfo else {
				return nil
		}
		return AudioRecordStopNotification(stopInfo: stopInfo)
	}
}

/** metering did finish **/
struct AudioRecordFinishNotification: NotificationConvertible {
	static let name: Notification.Name = .audioRecordFinishNotification
	
	struct FinishInfo {
		
	}
	
	var finishInfo: FinishInfo
	
	func asNotification() -> Notification {
		return Notification(name: .audioRecordFinishNotification, object: nil, userInfo: ["finishInfo": finishInfo])
	}
}

extension Notification {
	func toAudioRecordFinishNotification() -> AudioRecordFinishNotification? {
		guard name == .audioRecordFinishNotification,
			let finishInfo = userInfo?["finishInfo"] as? AudioRecordFinishNotification.FinishInfo else {
				return nil
		}
		return AudioRecordFinishNotification(finishInfo: finishInfo)
	}
}

/** metering did fail **/
struct AudioRecordFailNotification: NotificationConvertible {
	static let name: Notification.Name = .audioRecordFailNotification
	
	struct FailInfo {
		
	}
	
	var failInfo: FailInfo
	
	func asNotification() -> Notification {
		return Notification(name: .audioRecordFailNotification, object: nil, userInfo: ["failInfo": failInfo])
	}
}

extension Notification {
	func toAudioRecordFailNotification() -> AudioRecordFailNotification? {
		guard name == .audioRecordFailNotification,
			let failInfo = userInfo?["failInfo"] as? AudioRecordFailNotification.FailInfo else {
				return nil
		}
		return AudioRecordFailNotification(failInfo: failInfo)
	}
}
