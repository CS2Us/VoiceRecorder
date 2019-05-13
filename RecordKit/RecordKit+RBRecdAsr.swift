//
//  RecordKit+RBRecdAsr.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

public class RBWrapper: NSObject {
	public var dst: Destination
	public internal(set) var asrResult: String
	
	public override init() {
		dst = .documents(name: "RK", type: "m4a")
		asrResult = ""
		super.init()
	}
}

@objc
public protocol RBContextPt {
	var wrapper: RBWrapper { get set }
}

@objc
public protocol RBSessionHandle {
	@objc(rbStartContext:)
	optional func rbStart(context: RBContextPt)
	@objc(rbEndupContext:)
	optional func rbEndUp(context: RBContextPt)
	@objc(rbStopContext:)
	optional func rbStop(context: RBContextPt)
	@objc(rbResumeContext:)
	optional func rbResume(context: RBContextPt)
	@objc(rbExportContext:)
	optional func rbFinish(context: RBContextPt)
	@objc(rbTimesOutContext:)
	optional func rbTimesOut(context: RBContextPt)
}

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
		
		mainMixer = RKMixer(player, micBooster)
		
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
	
	public static func recordStart(_ ctx: RBContextPt) {
		RecordKit.shouldBeRunning = true
		RBRecdAsr.default.asrer.dst = ctx.wrapper.dst
		RBRecdAsr.default.asrer.longSpeechRecognition()
		if RKSettings.headPhonesPlugged {
			RBRecdAsr.default.micBooster.gain = 0
		}
		RBRecdAsr.default.recorder.record(ctx)
		
		RecordKit.rbObservers.allObjects
			.map{$0 as? RBSessionHandle}.filter{$0 != nil}.forEach { observer in
				observer?.rbStart?(context: ctx)
		}
	}
	
	public static func recordEndUp(_ ctx: RBContextPt) {
		RecordKit.shouldBeRunning = false
		RBRecdAsr.default.tape = RBRecdAsr.default.recorder.audioFile!
		RBRecdAsr.default.recorder.stop(ctx)
		RBRecdAsr.default.asrer.endRecognition()
		ctx.wrapper.asrResult = RBRecdAsr.default.asrer.finalResult ?? ""
		RBRecdAsr.default.player.load(audioFile: RBRecdAsr.default.tape)
		RBRecdAsr.default.tape.exportAsynchronously(
								  dst: ctx.wrapper.dst,
								  exportFormat: .m4a) { [weak ctx] _, exportError in
									guard let strongCtx = ctx else {
										RKLog("Export Ctx memory has been free")
										return
									}
									if let error = exportError {
										RKLog("Export Failed \(error)")
									} else {
										RKLog("Export succeeded")
										
										RecordKit.rbObservers.allObjects
											.map{$0 as? RBSessionHandle}.filter{$0 != nil}.forEach { observer in
												observer?.rbFinish?(context: strongCtx)
										}
									}
		}
		
		RecordKit.rbObservers.allObjects
			.map{$0 as? RBSessionHandle}.filter{$0 != nil}.forEach { observer in
				observer?.rbEndUp?(context: ctx)
		}
	}
	
	public static func recordStop(_ ctx: RBContextPt) {
		RecordKit.shouldBeRunning = false
		RBRecdAsr.default.recorder.stop(ctx)
		RBRecdAsr.default.asrer.endRecognition()
		
		RecordKit.rbObservers.allObjects
			.map{$0 as? RBSessionHandle}.filter{$0 != nil}.forEach { observer in
				observer?.rbStop?(context: ctx)
		}
	}
	
	public static func recordResume(_ ctx: RBContextPt) {
		RecordKit.shouldBeRunning = true
		RBRecdAsr.default.recorder.record(ctx)
		RBRecdAsr.default.asrer.longSpeechRecognition()
		
		RecordKit.rbObservers.allObjects
			.map{$0 as? RBSessionHandle}.filter{$0 != nil}.forEach { observer in
				observer?.rbResume?(context: ctx)
		}
	}
}
