//
//  RKMicrophone.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/12.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

/// Audio from the standard input
public class RKMicrophone: RKNode, RKToggleable {
	
	internal let mixer = AVAudioMixerNode()
	
	/// Output Volume (Default 1)
	public var volume: Double = 1.0 {
		didSet {
			volume = max(volume, 0)
			mixer.outputVolume = Float(volume)
		}
	}
	
	fileprivate var lastKnownVolume: Double = 1.0
	
	/// Set the actual microphone device
	public func setDevice(_ device: RKDevice) throws {
		do {
			try RecordKit.setInputDevice(device)
		} catch {
			RKLog("Could not set input device")
		}
	}
	
	/// Determine if the microphone is currently on.
	public var isStarted: Bool {
		return volume != 0.0
	}
	
	/// Initialize the microphone
	override public init() {
		super.init()
		self.avAudioNode = mixer
		RKSettings.audioInputEnabled = true
		
		let format = getFormatForDevice()
		// we have to connect the input at the original device sample rate, because once AVAudioEngine is initialized, it reports the wrong rate
		setAVSessionSampleRate(sampleRate: RecordKit.deviceSampleRate)
		RecordKit.engine.attach(avAudioUnitOrNode)
		RecordKit.engine.connect(RecordKit.engine.inputNode, to: self.avAudioNode, format: format!)
		setAVSessionSampleRate(sampleRate: RKSettings.sampleRate)
	}
	
	/// Function to start, play, or activate the node, all do the same thing
	public func start() {
		if isStopped {
			volume = lastKnownVolume
		}
	}
	
	/// Function to stop or bypass the node, both are equivalent
	public func stop() {
		if isPlaying {
			lastKnownVolume = volume
			volume = 0
		}
	}
	
	deinit {
		RKSettings.audioInputEnabled = false
	}
}

extension RKMicrophone {
	private func setAVSessionSampleRate(sampleRate: Double) {
		do {
			try AVAudioSession.sharedInstance().setPreferredSampleRate(sampleRate)
		} catch {
			RKLog(error)
		}
	}
	
	// Here is where we actually check the device type and make the settings, if needed
	private func getFormatForDevice() -> AVAudioFormat? {
		var audioFormat: AVAudioFormat?
		#if os(iOS) && !targetEnvironment(simulator)
		let currentFormat = RecordKit.engine.inputNode.inputFormat(forBus: 0)
		let desiredFS = RecordKit.deviceSampleRate
		if let layout = currentFormat.channelLayout {
			audioFormat = AVAudioFormat(commonFormat: currentFormat.commonFormat,
										sampleRate: desiredFS,
										interleaved: currentFormat.isInterleaved,
										channelLayout: layout)
		} else {
			audioFormat = AVAudioFormat(standardFormatWithSampleRate: desiredFS, channels: 1)
		}
		#else
		let desiredFS = RKSettings.sampleRate
		audioFormat = AVAudioFormat(standardFormatWithSampleRate: desiredFS, channels: 1)
		#endif
		return audioFormat
	}
}

//
//public func stop() {
//	engine.pause()
//	
//	RecordKit.microphoneObservers.allObjects
//		.map{$0 as? RKMicrophoneHandle}.filter{$0 != nil}.forEach { observer in
//			observer?.nodeRecorderStop?(self)
//	}
//}

