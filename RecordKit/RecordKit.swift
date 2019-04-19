//
//  RecordKit.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

public class RecordKit: NSObject {
	@objc public var inputStream: RKAudioInputStream?
	
	@objc public static let `default` = RecordKit()
	public var isRecording: Bool {
		if inputStream != nil {
			return true
		} else {
			return false
		}
	}
	
	open func recordStart(destinationURL: Destination, outputFileType: AudioFileTypeID, outputFormat: AudioFormatID) {
		recordStartInit()
		inputStream = RKAudioInputStream.inputStream()
		inputStream?.microphone?.inputFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .float32)
		inputStream?.audioConverter?.outputFormat = RKSettings.IOFormat(formatID: outputFormat, bitDepth: .int16)
		inputStream?.audioConverter?.outputUrl = destinationURL
		inputStream?.audioConverter?.outputFileType = outputFileType
		inputStream?.asrerConverter?.outputFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .int16, sampleRate: 16000)
		inputStream?.asrerConverter?.outputUrl = Destination.temp(url: "ASRTempFile.wav")
		inputStream?.asrerConverter?.outputFileType = kAudioFileWAVEType
		inputStream?.status = .open
		RKLog("outputUrl: \(destinationURL.url.absoluteString)")
	}
	
	open func recordCancle() {
		recordCancleDeinit()
		inputStream?.status = .closed
		inputStream = nil
	}
	
	private func recordStartInit() {
		try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP, .allowBluetooth, .duckOthers])
		try? AVAudioSession.sharedInstance().setPreferredIOBufferDuration(TimeInterval(10 / 1000))
		try? AVAudioSession.sharedInstance().setPreferredSampleRate(RKSettings.sampleRate)
		try? AVAudioSession.sharedInstance().setActive(true, options: [])
	}
	
	private func recordCancleDeinit() {
		try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
	}
	
	
}

@objc
public protocol RecordKitSessionHandle {
	// MARK:- Handle interruption
	@objc(handleInterruption:)
	func handleInterruption(notification: Notification)
	// MARK: - Handle RouteChange
	@objc(handleRouteChange:)
	func handleRouteChange(notification: Notification)
}

extension RecordKit: RecordKitSessionHandle {
	public func handleInterruption(notification: Notification) {
		if inputStream != nil {
			RecordKit.default.recordCancle()
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
}
