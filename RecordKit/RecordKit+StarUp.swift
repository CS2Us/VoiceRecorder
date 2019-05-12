//
//  RecordKit+Pro.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

/** RB: Record Business **/
fileprivate class RBRecdAsr {
	var asrer: RKASRer = RKASRer()
	var mic: RKMicrophone = RKMicrophone()
	var recorder: RKNodeRecorder!
	var tape: RKAudioFile!
	var micBooster: RKBooster!
	var micMixer: RKMixer!
	let recSettings:[String : Any] = [
		AVFormatIDKey: kAudioFormatLinearPCM,
		AVEncoderAudioQualityKey : AVAudioQuality.high,
		AVNumberOfChannelsKey: 2,
		AVSampleRateKey : 44100,
		AVLinearPCMBitDepthKey : 32
	]
	
	static var `default` = RBRecdAsr()
	
	init() {
//		let monoToStereo = RKStereoFieldLimiter(mic, amount: 1)
//		micMixer = RKMixer(monoToStereo)
//		micBooster = RKBooster(micMixer)
//		micBooster.gain = 0
		
//		RecordKit.output = micMixer
		
		sessionShouldBeInit()
	}
	
	deinit {
		sessionShouldBeDeinit()
		RKLog("业务流程销毁")
	}
}

extension RecordKit {
	public static func recordStart() {
		RecordKit.shouldBeRunning = true
		let dst: Destination = .cache(name: "RK", type: "caf")
		let inputNode: RKNode = RBRecdAsr.default.mic
		let recSettings: [String:Any] = RBRecdAsr.default.recSettings
		RBRecdAsr.default.recorder = try! RKNodeRecorder(node: inputNode, file: RKAudioFile(writeIn: dst, settings: recSettings))
//		RBRecdAsr.default.asrer.dst = dst
//		RBRecdAsr.default.asrer.longSpeechRecognition()
		RBRecdAsr.default.recorder.record()
		try? RecordKit.engine.start()
	}
	
	public static func recordCancle() {
		RecordKit.shouldBeRunning = false
		RBRecdAsr.default.recorder?.stop()
		RBRecdAsr.default.tape.exportAsynchronously(
								  dst: .documents(name: "RK", type: "m4a"),
								  exportFormat: .m4a) {_, exportError in
									if let error = exportError {
										RKLog("Export Failed \(error)")
									} else {
										RKLog("Export succeeded")
									}
		}
		RecordKit.engine.stop()
	}
	
	public static func recordStop() {
		RecordKit.shouldBeRunning = false
	}
	
	public static func recordResume() {
		RecordKit.shouldBeRunning = true
	}
}

extension RBRecdAsr: RecordKitSessionHandle {
	public func handleInterruption(notification: Notification) {
		if RecordKit.shouldBeRunning {
			RecordKit.recordCancle()
		}
	}
	
	public func handleRouteChange(notification: Notification) {
		guard let userInfo = notification.userInfo,
			let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
			let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
				return
		}
		switch reason {
		case .newDeviceAvailable:
			let session = AVAudioSession.sharedInstance()
			for output in session.currentRoute.outputs where output.portType == AVAudioSession.Port.bluetoothA2DP {
				break
			}
		case .oldDeviceUnavailable:
			if let previousRoute =
				userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
				for output in previousRoute.outputs where output.portType == AVAudioSession.Port.bluetoothA2DP {
					break
				}
			}
		default: ()
		}
	}
	
	public func sessionShouldBeInit() {
		try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP, .allowBluetooth, .duckOthers])
		try? AVAudioSession.sharedInstance().setPreferredIOBufferDuration(RKSettings.bufferLength.duration)
		try? AVAudioSession.sharedInstance().setPreferredSampleRate(RKSettings.sampleRate)
		try? AVAudioSession.sharedInstance().setActive(true, options: [])
	}
	
	public func sessionShouldBeDeinit() {
		try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
	}
}
