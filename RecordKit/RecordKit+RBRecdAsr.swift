//
//  RecordKit+RBRecdAsr.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

/** RB: Record Business **/
public class RBRecdAsr {
	fileprivate var asrer: RKASRer = RKASRer()
	fileprivate var tape: RKAudioFile!
	fileprivate var micBooster: RKBooster!
	fileprivate var micMixer: RKMixer!
	fileprivate var mainMixer: RKMixer!
	
	public var moogLadder: RKMoogLadder!
	public var mic: RKMicrophone = RKMicrophone()
	public var player: RKPlayer!
	public var recorder: RKNodeRecorder!
	public var dst: Destination = .documents(name: "RK", type: "m4a")

	static var `default` = RBRecdAsr()
	
	init() {
		RKSettings.bufferLength = .medium
		
		do {
			try RKSettings.setSession(category: .playAndRecord, with: [.allowBluetoothA2DP])
		} catch {
			RKLog("Could not set session category.")
		}
		
		RKSettings.defaultToSpeaker = true
		RKSettings.useBluetooth = true
		
		// Patching
		let monoToStereo = RKStereoFieldLimiter(mic, amount: 1)
		micMixer = RKMixer(monoToStereo)
		micBooster = RKBooster(micMixer)
		// Will set the level of microphone monitoring
		micBooster.gain = 0
		
		recorder = try! RKNodeRecorder(node: micMixer)
		if let file = recorder.audioFile {
			player = RKPlayer(audioFile: file)
		}
		player.isLooping = true
		
		moogLadder = RKMoogLadder(player)
		moogLadder.cutoffFrequency = 20_000
		moogLadder.resonance = 0.5
		
		mainMixer = RKMixer(moogLadder, micBooster)
		
		RecordKit.output = mainMixer
		do {
			try RecordKit.start()
		} catch {
			RKLog("RecordKit did not start!")
		}
	}
	
	deinit {
		RKLog("业务流程销毁")
	}
}

extension RecordKit {
	public static var rb: RBRecdAsr {
		return RBRecdAsr.default
	}
	
	public static func recordStart() {
		RecordKit.shouldBeRunning = true
		let dst: Destination = RBRecdAsr.default.dst
		RBRecdAsr.default.asrer.dst = dst
		RBRecdAsr.default.asrer.longSpeechRecognition()
		if RKSettings.headPhonesPlugged {
			RBRecdAsr.default.micBooster.gain = 0
		}
		RBRecdAsr.default.recorder.record()
	}
	
	public static func recordCancle() {
		RecordKit.shouldBeRunning = false
		RBRecdAsr.default.tape = RBRecdAsr.default.recorder.audioFile!
		RBRecdAsr.default.recorder?.stop()
		RBRecdAsr.default.asrer.endRecognition()
		RBRecdAsr.default.player.load(audioFile: RBRecdAsr.default.tape)
		RBRecdAsr.default.tape.exportAsynchronously(
								  dst: RBRecdAsr.default.dst,
								  exportFormat: .m4a) {_, exportError in
									if let error = exportError {
										RKLog("Export Failed \(error)")
									} else {
										RKLog("Export succeeded")
									}
		}
	}
	
	public static func recordStop() {
		RecordKit.shouldBeRunning = false
	}
	
	public static func recordResume() {
		RecordKit.shouldBeRunning = true
	}
}
