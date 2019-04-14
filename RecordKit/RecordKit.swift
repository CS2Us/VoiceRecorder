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
	private var audioRecorder: AVAudioRecorder?
	
	public static let `default` = RecordKit()
	
	public override init() {
		super.init()
		do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: [.defaultToSpeaker])
			try AVAudioSession.sharedInstance().setActive(true, options: [])
		} catch let ex {
			RKLog("RecordKit.Error... \(ex)")
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
//		let settings = [
//			AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//			AVSampleRateKey: 44100,
//			AVNumberOfChannelsKey: 1,
//			AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//		]
//
//		do {
//			audioRecorder = try AVAudioRecorder(url: destinationURL.url, settings: settings)
//			audioRecorder?.record()
//		} catch let ex {
//			RKLog("错误: \(ex)")
//		}
	}
	
	open func recordEndup() {
		inputStream?.status = .closed
//		audioRecorder?.stop()
	}
	
	open func recordCancle() {
		inputStream = nil
	}
}

