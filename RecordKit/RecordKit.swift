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
			RKLog("RecordKit.Error... AVAudioSession")
		}
	}
	
	open func recordStart(destinationURL: Destination, outputFileType: AudioFileTypeID, outputFormat: AudioFormatID) {
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
	
	open func recordEndup() {
		inputStream?.status = .closed
	}
	
	open func recordCancle() {
		inputStream = nil
	}
}

