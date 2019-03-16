//
//  RecordKit.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

extension Notification.Name {
	static let microphoneBufferList: Notification.Name = Notification.Name("microphoneBufferList")
	static let microphoneFloatBuffer: Notification.Name = Notification.Name("microphoneFloatBuffer")
	static let audioFileConvertComplete: Notification.Name = Notification.Name("audioFileConvertDidComplete")
	static let audioFileConvertError: Notification.Name = Notification.Name("audioFileConvertError")
}

public class RecordKit: NSObject {
	private var inputStream: RKAudioInputStream?
	
	public static let `default` = RecordKit()
	
	public override init() {
		super.init()
		do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: [])
			try AVAudioSession.sharedInstance().setActive(true, options: [])
			try AVAudioSession.sharedInstance().setPreferredSampleRate(RKSettings.sampleRate)
			try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(RKSettings.bufferLength.duration)
		} catch {
			RKLog("RecordKit.Error... AvAudioSession")
		}
	}
	
	open func recordStart(destinationURL: Destination, outputFileType: AudioFileTypeID, outputFormat: AudioFormatID) {
		inputStream = RKAudioInputStream.inputStream()
		inputStream?.microphone?.inputFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .int16)
//		inputStream?.audioConverter?.inputUrl = Destination.resource(name: "HappyBirthdaySong", type: "mp3").url
		inputStream?.audioConverter?.outputFormat = RKSettings.IOFormat(formatID: outputFormat, bitDepth: .int16)
		inputStream?.audioConverter?.outputUrl = destinationURL.url
		inputStream?.audioConverter?.outputFileType = outputFileType
		inputStream?.asrerConverter?.outputFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .int16, sampleRate: 16000)
		inputStream?.asrerConverter?.outputUrl = RKSettings.asrFileDst.url
		inputStream?.asrerConverter?.outputFileType = kAudioFileWAVEType
		RKLog("outputUrl: \(destinationURL.url)")
		
		inputStream?.status = .open
		
	}
	
	open func recordEndup() {
		inputStream?.status = .closed
		inputStream = nil
	}
}

extension RecordKit: RKASRerDelegate {
	func asr(_ asr: RKASRer, recognitionResult: String) {
		RKLog("recognitionContinue...")
	}
}

extension RecordKit: AVAudioPlayerDelegate {
	public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		RKLog("audioPlayerDidFinishPlaying")
	}
	
	public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
		RKLog("audioPlayerDecodeErrorDidOccur")
	}
}
